output "cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_private_fqdn" {
  description = "Private FQDN of the AKS API server"
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "node_resource_group" {
  description = "Auto-generated resource group containing AKS node resources (VMSS, NICs, etc.)"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the cluster (sensitive)"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL (used for workload identity federation)"
  value       = var.oidc_issuer_enabled ? azurerm_kubernetes_cluster.this.oidc_issuer_url : null
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity (useful for downstream role assignments)"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "windows_node_pool_id" {
  description = "Resource ID of the Windows node pool (null if not enabled)"
  value       = var.enable_windows_node_pools ? azurerm_kubernetes_cluster_node_pool.windows[0].id : null
}

output "linux_node_pool_ids" {
  description = "Map of additional Linux node pool name → resource ID"
  value       = { for k, v in azurerm_kubernetes_cluster_node_pool.linux : k => v.id }
}
