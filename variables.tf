##############################################################################
# Root module — variables
##############################################################################

# ── Core ──────────────────────────────────────────────────────────────────────
variable "cluster_name" {
  description = "Name of the AKS cluster and resource name prefix"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to create"
  type        = string
}

variable "location" {
  description = "Azure region (e.g. eastus, westeurope)"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version string (e.g. '1.29')"
  type        = string
}

variable "sku_tier" {
  description = "AKS pricing tier: Free | Standard | Premium"
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ── Network ───────────────────────────────────────────────────────────────────
variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}

variable "node_pool_subnet_cidr" {
  type    = list(string)
  default = ["10.1.0.0/16"]
}

variable "private_dns_zone_name" {
  description = "Private DNS zone name. Format: privatelink.<region>.azmk8s.io"
  type        = string
}

variable "custom_dns_servers" {
  description = "Custom DNS server IPs for VNet (required for gMSA / AD integration)"
  type        = list(string)
  default     = []
}

variable "additional_subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {}
}

variable "additional_vnet_links" {
  description = "Extra VNet IDs to link to the private DNS zone"
  type        = map(string)
  default     = {}
}

variable "dns_service_ip" {
  type    = string
  default = "10.2.0.10"
}

variable "service_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "pod_cidr" {
  description = "Pod CIDR for Azure CNI Overlay (independent of VNet address space)"
  type        = string
  default     = "10.244.0.0/16"
}

variable "outbound_type" {
  type    = string
  default = "userDefinedRouting"
}

# ── Identity ──────────────────────────────────────────────────────────────────
variable "acr_id" {
  description = "Optional ACR resource ID for AcrPull role assignment on kubelet identity"
  type        = string
  default     = null
}

# ── System node pool ──────────────────────────────────────────────────────────
variable "system_node_pool_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "system_node_count" {
  type    = number
  default = 3
}

variable "system_node_pool_min_count" {
  type    = number
  default = 2
}

variable "system_node_pool_max_count" {
  type    = number
  default = 5
}

# ── Additional Linux node pools ───────────────────────────────────────────────
variable "linux_node_pools" {
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
  type = object({
    balance_similar_node_groups      = optional(bool, false)
    expander                         = optional(string, "random")
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
  type    = bool
  default = false
}

variable "windows_profile" {
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
  type = object({
    azure_rbac_enabled     = optional(bool, true)
    admin_group_object_ids = optional(list(string), [])
  })
  default = null
}

# ── Feature flags ─────────────────────────────────────────────────────────────
variable "local_account_disabled" {
  type    = bool
  default = true
}

variable "azure_policy_enabled" {
  type    = bool
  default = true
}

variable "oidc_issuer_enabled" {
  type    = bool
  default = true
}

variable "enable_secret_store_csi" {
  type    = bool
  default = false
}

variable "maintenance_window" {
  type = object({
    day   = string
    hours = list(number)
  })
  default = null
}
