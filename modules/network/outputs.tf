output "vnet_id" {
  description = "Resource ID of the VNet"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the VNet"
  value       = azurerm_virtual_network.this.name
}

output "node_pool_subnet_id" {
  description = "Resource ID of the primary node pool subnet"
  value       = azurerm_subnet.node_pool.id
}

output "additional_subnet_ids" {
  description = "Map of additional subnet name → resource ID"
  value       = { for k, v in azurerm_subnet.additional : k => v.id }
}

output "private_dns_zone_id" {
  description = "Resource ID of the AKS private DNS zone"
  value       = azurerm_private_dns_zone.aks.id
}

output "private_dns_zone_name" {
  description = "Name of the AKS private DNS zone"
  value       = azurerm_private_dns_zone.aks.name
}
