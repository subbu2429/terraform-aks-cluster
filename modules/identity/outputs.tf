output "control_plane_identity_id" {
  description = "Resource ID of the control plane user-assigned identity"
  value       = azurerm_user_assigned_identity.control_plane.id
}

output "control_plane_identity_principal_id" {
  description = "Principal (object) ID of the control plane identity"
  value       = azurerm_user_assigned_identity.control_plane.principal_id
}

output "kubelet_identity_id" {
  description = "Resource ID of the kubelet user-assigned identity"
  value       = azurerm_user_assigned_identity.kubelet.id
}

output "kubelet_identity_client_id" {
  description = "Client ID of the kubelet identity (used in kubelet_identity block)"
  value       = azurerm_user_assigned_identity.kubelet.client_id
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity (used in kubelet_identity block)"
  value       = azurerm_user_assigned_identity.kubelet.principal_id
}
