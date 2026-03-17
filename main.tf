##############################################################################
# Root module
# Orchestrates: network → identity → aks
# Dependency order is explicit via depends_on to ensure role assignments
# exist before the AKS cluster attempts to provision.
##############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Recommended: configure remote state backend
  # backend "azurerm" {
  #   resource_group_name  = "tf-state-rg"
  #   storage_account_name = "tfstate<unique>"
  #   container_name       = "tfstate"
  #   key                  = "aks-cluster.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

# ── Resource group ────────────────────────────────────────────────────────────
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ── Module: network ───────────────────────────────────────────────────────────
module "network" {
  source = "./modules/network"

  cluster_name          = var.cluster_name
  resource_group_name   = azurerm_resource_group.this.name
  location              = var.location
  vnet_address_space    = var.vnet_address_space
  node_pool_subnet_cidr = var.node_pool_subnet_cidr
  private_dns_zone_name = var.private_dns_zone_name
  custom_dns_servers    = var.custom_dns_servers
  additional_subnets    = var.additional_subnets
  additional_vnet_links = var.additional_vnet_links
  tags                  = var.tags
}

# ── Module: identity ──────────────────────────────────────────────────────────
# Depends on network so it can create role assignments against the DNS zone
# and subnet IDs that the network module produces.
module "identity" {
  source = "./modules/identity"

  cluster_name          = var.cluster_name
  resource_group_name   = azurerm_resource_group.this.name
  location              = var.location
  private_dns_zone_id   = module.network.private_dns_zone_id
  subnet_id             = module.network.node_pool_subnet_id
  acr_id                = var.acr_id
  tags                  = var.tags
}

# ── Module: aks ───────────────────────────────────────────────────────────────
# depends_on forces Terraform to wait for ALL identity role assignments to
# complete before submitting the cluster PUT request. Without this, AKS
# provisioning may race the RBAC propagation and fail with AuthorizationFailed.
module "aks" {
  source = "./modules/aks"

  cluster_name        = var.cluster_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier
  tags                = var.tags

  # Networking
  private_dns_zone_id = module.network.private_dns_zone_id
  node_pool_subnet_id = module.network.node_pool_subnet_id
  dns_service_ip      = var.dns_service_ip
  service_cidr        = var.service_cidr
  pod_cidr            = var.pod_cidr
  outbound_type       = var.outbound_type

  # Identity
  control_plane_identity_id  = module.identity.control_plane_identity_id
  kubelet_identity_id        = module.identity.kubelet_identity_id
  kubelet_identity_client_id = module.identity.kubelet_identity_client_id
  kubelet_identity_object_id = module.identity.kubelet_identity_object_id

  # System node pool
  system_node_pool_vm_size   = var.system_node_pool_vm_size
  system_node_count          = var.system_node_count
  system_node_pool_min_count = var.system_node_pool_min_count
  system_node_pool_max_count = var.system_node_pool_max_count

  # Additional Linux node pools
  linux_node_pools = var.linux_node_pools

  # Autoscaler
  autoscaler_profile = var.autoscaler_profile

  # Windows / gMSA
  enable_windows_node_pools = var.enable_windows_node_pools
  windows_profile           = var.windows_profile
  windows_node_pool         = var.windows_node_pool

  # AAD RBAC
  aad_rbac = var.aad_rbac

  # Optional features
  local_account_disabled  = var.local_account_disabled
  azure_policy_enabled    = var.azure_policy_enabled
  oidc_issuer_enabled     = var.oidc_issuer_enabled
  enable_secret_store_csi = var.enable_secret_store_csi
  maintenance_window      = var.maintenance_window

  depends_on = [
    module.identity,
    module.network,
  ]
}
