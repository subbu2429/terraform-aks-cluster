output "cluster_id" {
  description = "AKS cluster resource ID"
  value       = module.aks.cluster_id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "cluster_private_fqdn" {
  description = "Private FQDN of the AKS API server"
  value       = module.aks.cluster_private_fqdn
}

output "node_resource_group" {
  description = "Auto-generated node resource group"
  value       = module.aks.node_resource_group
}

output "kube_config_raw" {
  description = "Raw kubeconfig (sensitive)"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = module.aks.oidc_issuer_url
}

output "vnet_id" {
  description = "VNet resource ID"
  value       = module.network.vnet_id
}

output "node_pool_subnet_id" {
  description = "Node pool subnet resource ID"
  value       = module.network.node_pool_subnet_id
}

output "private_dns_zone_id" {
  description = "Private DNS zone resource ID"
  value       = module.network.private_dns_zone_id
}

output "control_plane_identity_id" {
  description = "Control plane managed identity resource ID"
  value       = module.identity.control_plane_identity_id
}

output "kubelet_identity_id" {
  description = "Kubelet managed identity resource ID"
  value       = module.identity.kubelet_identity_id
}
