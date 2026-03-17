##############################################################################
# AKS module — variables
##############################################################################

# ── Core ──────────────────────────────────────────────────────────────────────
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy the cluster into"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version (e.g. '1.29')"
  type        = string
}

variable "sku_tier" {
  description = "AKS pricing tier: Free | Standard | Premium"
  type        = string
  default     = "Standard"
}

variable "local_account_disabled" {
  description = "Disable local Kubernetes accounts (enforce AAD auth)"
  type        = bool
  default     = true
}

variable "azure_policy_enabled" {
  description = "Enable the Azure Policy add-on"
  type        = bool
  default     = true
}

variable "oidc_issuer_enabled" {
  description = "Enable OIDC issuer and workload identity"
  type        = bool
  default     = true
}

variable "enable_secret_store_csi" {
  description = "Enable the Secrets Store CSI driver (Key Vault integration)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all AKS resources"
  type        = map(string)
  default     = {}
}

# ── Networking ────────────────────────────────────────────────────────────────
variable "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone for the cluster"
  type        = string
}

variable "node_pool_subnet_id" {
  description = "Resource ID of the subnet used by all node pools"
  type        = string
}

variable "dns_service_ip" {
  description = "IP address for the Kubernetes DNS service (must be within service_cidr)"
  type        = string
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
}

variable "pod_cidr" {
  description = "CIDR for pods (Azure CNI Overlay — separate from VNet)"
  type        = string
}

variable "outbound_type" {
  description = "Outbound routing type: userDefinedRouting | loadBalancer | managedNATGateway"
  type        = string
  default     = "userDefinedRouting"
}

# ── Identity ──────────────────────────────────────────────────────────────────
variable "control_plane_identity_id" {
  description = "Resource ID of the control plane user-assigned managed identity"
  type        = string
}

variable "kubelet_identity_id" {
  description = "Resource ID of the kubelet user-assigned managed identity"
  type        = string
}

variable "kubelet_identity_client_id" {
  description = "Client ID of the kubelet managed identity"
  type        = string
}

variable "kubelet_identity_object_id" {
  description = "Object (principal) ID of the kubelet managed identity"
  type        = string
}

# ── System node pool ──────────────────────────────────────────────────────────
variable "system_node_pool_vm_size" {
  description = "VM size for the system node pool"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "system_node_count" {
  description = "Initial node count for the system pool"
  type        = number
  default     = 3
}

variable "system_node_pool_min_count" {
  description = "Minimum node count for system pool autoscaler"
  type        = number
  default     = 2
}

variable "system_node_pool_max_count" {
  description = "Maximum node count for system pool autoscaler"
  type        = number
  default     = 5
}

variable "system_node_labels" {
  description = "Labels to apply to system pool nodes"
  type        = map(string)
  default     = {}
}

# ── Additional Linux node pools ───────────────────────────────────────────────
variable "linux_node_pools" {
  description = "Map of additional Linux node pools to create"
  type = map(object({
    vm_size         = string
    min_count       = number
    max_count       = number
    node_count      = optional(number, 1)
    os_disk_size_gb = optional(number, 128)
    node_labels     = optional(map(string), {})
    node_taints     = optional(list(string), [])
    mode            = optional(string, "User")
  }))
  default = {}
}

# ── Autoscaler profile ────────────────────────────────────────────────────────
variable "autoscaler_profile" {
  description = "Cluster-wide autoscaler tuning. All fields are optional with sane defaults."
  type = object({
    balance_similar_node_groups      = optional(bool, false)
    expander                         = optional(string, "random") # random | least-waste | most-pods | priority
    max_graceful_termination_sec     = optional(string, "600")
    max_node_provisioning_time       = optional(string, "15m")
    max_unready_nodes                = optional(number, 3)
    max_unready_percentage           = optional(number, 45)
    new_pod_scale_up_delay           = optional(string, "10s")
    scale_down_delay_after_add       = optional(string, "10m")
    scale_down_delay_after_delete    = optional(string, "10s")
    scale_down_delay_after_failure   = optional(string, "3m")
    scale_down_unneeded              = optional(string, "10m")
    scale_down_unready               = optional(string, "20m")
    scale_down_utilization_threshold = optional(string, "0.5")
    empty_bulk_delete_max            = optional(string, "10")
    skip_nodes_with_local_storage    = optional(bool, true)
    skip_nodes_with_system_pods      = optional(bool, true)
  })
  default = {}
}

# ── Windows / gMSA ────────────────────────────────────────────────────────────
variable "enable_windows_node_pools" {
  description = "Set to true to enable Windows profile and provision a Windows node pool"
  type        = bool
  default     = false
}

variable "windows_profile" {
  description = <<-EOT
    Windows node pool admin credentials and optional gMSA configuration.
    admin_password should be sourced from Key Vault — do not hardcode in tfvars.
    gmsa.dns_server must be an AD DC IP reachable from the node pool subnet.
    gmsa.root_domain must match your AD domain FQDN (e.g. corp.contoso.com).
  EOT
  type = object({
    admin_username = string
    admin_password = string
    gmsa = optional(object({
      dns_server  = string
      root_domain = string
    }), null)
  })
  default   = null
  sensitive = true
}

variable "windows_node_pool" {
  description = "Configuration for the Windows node pool (used when enable_windows_node_pools = true)"
  type = object({
    name            = optional(string, "win")
    vm_size         = optional(string, "Standard_D4s_v5")
    min_count       = optional(number, 1)
    max_count       = optional(number, 3)
    node_count      = optional(number, 1)
    os_disk_size_gb = optional(number, 256)
    node_labels     = optional(map(string), {})
    node_taints     = optional(list(string), ["os=windows:NoSchedule"])
  })
  default = {}
}

# ── AAD RBAC ──────────────────────────────────────────────────────────────────
variable "aad_rbac" {
  description = "Azure AD RBAC configuration"
  type = object({
    azure_rbac_enabled     = optional(bool, true)
    admin_group_object_ids = optional(list(string), [])
  })
  default = null
}

# ── Maintenance window ────────────────────────────────────────────────────────
variable "maintenance_window" {
  description = "Preferred maintenance window for AKS auto-upgrades"
  type = object({
    day   = string       # e.g. "Sunday"
    hours = list(number) # e.g. [2, 3] for 02:00–03:00 UTC
  })
  default = null
}
