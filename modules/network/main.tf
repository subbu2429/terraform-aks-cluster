##############################################################################
# Module: network
# Provisions VNet, node pool subnet, private DNS zone and VNet link.
# Outputs are consumed by both the identity and aks modules.
##############################################################################

resource "azurerm_virtual_network" "this" {
  name                = "${var.cluster_name}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  dns_servers         = var.custom_dns_servers
  tags                = var.tags
}

resource "azurerm_subnet" "node_pool" {
  name                 = "node-pool-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.node_pool_subnet_cidr

  # Required for Azure CNI Overlay — disables subnet-level private endpoint policies
  private_endpoint_network_policies = "Disabled"
}

# Additional subnets (e.g. for ingress, private endpoints, jump hosts)
resource "azurerm_subnet" "additional" {
  for_each = var.additional_subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
}

# ── Private DNS zone ──────────────────────────────────────────────────────────

resource "azurerm_private_dns_zone" "aks" {
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "${var.cluster_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}

# Optional: additional VNet links (e.g. hub VNet for spoke-hub topology)
resource "azurerm_private_dns_zone_virtual_network_link" "additional" {
  for_each = var.additional_vnet_links

  name                  = each.key
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = each.value
  registration_enabled  = false
  tags                  = var.tags
}
