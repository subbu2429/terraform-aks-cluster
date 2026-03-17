variable "cluster_name" {
  description = "Name prefix for network resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for all network resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "node_pool_subnet_cidr" {
  description = "Address prefix for the primary node pool subnet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "private_dns_zone_name" {
  description = "Private DNS zone name for the AKS private cluster. Format: privatelink.<region>.azmk8s.io"
  type        = string
}

variable "custom_dns_servers" {
  description = "Custom DNS server IPs for the VNet (e.g. your AD DC). Leave empty to use Azure default."
  type        = list(string)
  default     = []
}

variable "additional_subnets" {
  description = "Map of extra subnets to create inside the VNet (e.g. ingress, private-endpoints)"
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {}
}

variable "additional_vnet_links" {
  description = "Map of extra VNet IDs to link to the private DNS zone (e.g. hub VNet)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all network resources"
  type        = map(string)
  default     = {}
}
