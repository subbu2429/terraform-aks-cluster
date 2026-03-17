variable "cluster_name" {
  description = "Name of the AKS cluster (used as identity name prefix)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create identities in"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "private_dns_zone_id" {
  description = "ID of the private DNS zone — control plane identity needs Contributor on this"
  type        = string
}

variable "subnet_id" {
  description = "ID of the node pool subnet — control plane identity needs Network Contributor"
  type        = string
}

variable "acr_id" {
  description = "Optional ACR resource ID. Grants kubelet identity AcrPull if provided."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all identity resources"
  type        = map(string)
  default     = {}
}
