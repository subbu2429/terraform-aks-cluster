##############################################################################
# Module: aks
# Provisions the AKS private cluster with:
#   - Azure CNI Overlay networking
#   - User-assigned managed identity (control plane + kubelet)
#   - Cluster autoscaler profile
#   - Optional Windows node pool with gMSA support
##############################################################################

resource "azurerm_kubernetes_cluster" "this" {
  name                               = var.cluster_name
  resource_group_name                = var.resource_group_name
  location                           = var.location
  kubernetes_version                 = var.kubernetes_version
  dns_prefix_private_cluster         = var.cluster_name
  sku_tier                           = var.sku_tier
  private_cluster_enabled            = true
  private_dns_zone_id                = var.private_dns_zone_id
  private_cluster_public_fqdn_enabled = false
  local_account_disabled             = var.local_account_disabled
  azure_policy_enabled               = var.azure_policy_enabled
  oidc_issuer_enabled                = var.oidc_issuer_enabled
  workload_identity_enabled          = var.oidc_issuer_enabled # requires OIDC

  tags = var.tags

  # ── Identity ──────────────────────────────────────────────────────────────
  identity {
    type         = "UserAssigned"
    identity_ids = [var.control_plane_identity_id]
  }

  kubelet_identity {
    client_id                 = var.kubelet_identity_client_id
    object_id                 = var.kubelet_identity_object_id
    user_assigned_identity_id = var.kubelet_identity_id
  }

  # ── Default (system) node pool ────────────────────────────────────────────
  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool_vm_size
    vnet_subnet_id               = var.node_pool_subnet_id
    auto_scaling_enabled         = true
    min_count                    = var.system_node_pool_min_count
    max_count                    = var.system_node_pool_max_count
    node_count                   = var.system_node_count
    os_disk_size_gb              = 128
    os_disk_type                 = "Ephemeral"
    type                         = "VirtualMachineScaleSets"
    only_critical_addons_enabled = true # taint: CriticalAddonsOnly=true:NoSchedule
    node_labels                  = var.system_node_labels

    upgrade_settings {
      max_surge = "33%"
    }
  }

  # ── Networking ────────────────────────────────────────────────────────────
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"   # Azure CNI Overlay — pods don't consume VNet IPs
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    pod_cidr            = var.pod_cidr
    outbound_type       = var.outbound_type # userDefinedRouting recommended for private clusters
  }

  # ── Cluster autoscaler profile ────────────────────────────────────────────
  auto_scaler_profile {
    balance_similar_node_groups      = var.autoscaler_profile.balance_similar_node_groups
    expander                         = var.autoscaler_profile.expander
    max_graceful_termination_sec     = var.autoscaler_profile.max_graceful_termination_sec
    max_node_provisioning_time       = var.autoscaler_profile.max_node_provisioning_time
    max_unready_nodes                = var.autoscaler_profile.max_unready_nodes
    max_unready_percentage           = var.autoscaler_profile.max_unready_percentage
    new_pod_scale_up_delay           = var.autoscaler_profile.new_pod_scale_up_delay
    scale_down_delay_after_add       = var.autoscaler_profile.scale_down_delay_after_add
    scale_down_delay_after_delete    = var.autoscaler_profile.scale_down_delay_after_delete
    scale_down_delay_after_failure   = var.autoscaler_profile.scale_down_delay_after_failure
    scale_down_unneeded              = var.autoscaler_profile.scale_down_unneeded
    scale_down_unready               = var.autoscaler_profile.scale_down_unready
    scale_down_utilization_threshold = var.autoscaler_profile.scale_down_utilization_threshold
    empty_bulk_delete_max            = var.autoscaler_profile.empty_bulk_delete_max
    skip_nodes_with_local_storage    = var.autoscaler_profile.skip_nodes_with_local_storage
    skip_nodes_with_system_pods      = var.autoscaler_profile.skip_nodes_with_system_pods
  }

  # ── Windows profile (optional, gMSA-capable) ──────────────────────────────
  # Enabled when var.enable_windows_node_pools = true.
  # gMSA requires AD DNS reachable from within the VNet and a valid root_domain.
  dynamic "windows_profile" {
    for_each = var.enable_windows_node_pools && var.windows_profile != null ? [var.windows_profile] : []
    content {
      admin_username = windows_profile.value.admin_username
      admin_password = windows_profile.value.admin_password

      dynamic "gmsa" {
        for_each = windows_profile.value.gmsa != null ? [windows_profile.value.gmsa] : []
        content {
          dns_server  = gmsa.value.dns_server
          root_domain = gmsa.value.root_domain
        }
      }
    }
  }

  # ── Azure AD / RBAC ───────────────────────────────────────────────────────
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.aad_rbac != null ? [var.aad_rbac] : []
    content {
      azure_rbac_enabled     = azure_active_directory_role_based_access_control.value.azure_rbac_enabled
      admin_group_object_ids = azure_active_directory_role_based_access_control.value.admin_group_object_ids
    }
  }

  # ── Key Vault secrets provider (optional) ────────────────────────────────
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_secret_store_csi ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }
  }

  # ── Maintenance window ────────────────────────────────────────────────────
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      allowed {
        day   = maintenance_window.value.day
        hours = maintenance_window.value.hours
      }
    }
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count, # managed by cluster autoscaler
      kubernetes_version,              # managed via separate upgrade process
    ]
  }
}

# ── Additional Linux node pool ────────────────────────────────────────────────
resource "azurerm_kubernetes_cluster_node_pool" "linux" {
  for_each = var.linux_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.node_pool_subnet_id
  os_type               = "Linux"
  os_sku                = "Ubuntu"
  auto_scaling_enabled  = true
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  node_count            = each.value.node_count
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = "Ephemeral"
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  mode                  = each.value.mode
  tags                  = var.tags

  upgrade_settings {
    max_surge = "33%"
  }
}

# ── Windows node pool (optional) ──────────────────────────────────────────────
# Requires enable_windows_node_pools = true and windows_profile to be set.
# Nodes are tainted os=windows:NoSchedule by default to prevent Linux workloads
# from scheduling here.
resource "azurerm_kubernetes_cluster_node_pool" "windows" {
  count = var.enable_windows_node_pools ? 1 : 0

  name                  = var.windows_node_pool.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.windows_node_pool.vm_size
  vnet_subnet_id        = var.node_pool_subnet_id
  os_type               = "Windows"
  os_sku                = "Windows2022"
  auto_scaling_enabled  = true
  min_count             = var.windows_node_pool.min_count
  max_count             = var.windows_node_pool.max_count
  node_count            = var.windows_node_pool.node_count
  os_disk_size_gb       = var.windows_node_pool.os_disk_size_gb
  node_labels           = var.windows_node_pool.node_labels
  node_taints           = var.windows_node_pool.node_taints
  tags                  = var.tags

  upgrade_settings {
    max_surge = "33%"
  }
}
