##############################################################################
# Module: identity
# Creates user-assigned managed identities for AKS control plane and kubelet,
# and wires up all required role assignments before cluster provisioning.
##############################################################################

resource "azurerm_user_assigned_identity" "control_plane" {
  name                = "${var.cluster_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "${var.cluster_name}-kubelet-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# ── Role assignments ──────────────────────────────────────────────────────────

# Control plane → Private DNS Zone Contributor
# Required for private cluster to manage A records in the custom DNS zone.
resource "azurerm_role_assignment" "dns_contributor" {
  scope                = var.private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.control_plane.principal_id
}

# Control plane → Network Contributor on node pool subnet
# Required for Azure CNI to manage NIC/IP configuration on nodes.
resource "azurerm_role_assignment" "network_contributor" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.control_plane.principal_id
}

# Control plane → Managed Identity Operator on kubelet identity
# Allows AKS to assign the kubelet identity to VMSS node instances.
resource "azurerm_role_assignment" "managed_identity_operator" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.control_plane.principal_id
}

# Kubelet → AcrPull (optional)
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.acr_id != null ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}
