# Changelog

All notable changes to this Terraform module are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/).

---

## [1.1.0] — 2026-03-17

### Added
- **Cluster autoscaler profile** (`auto_scaler_profile` block) with full tunability:
  - `expander` strategy (random, least-waste, most-pods, priority)
  - `balance_similar_node_groups` for even spread
  - All scale-down delay and threshold parameters exposed as optional variables with safe defaults
- **Windows node pool** support (`azurerm_kubernetes_cluster_node_pool` with `os_type = "Windows"`, `os_sku = "Windows2022"`)
- **gMSA (Group Managed Service Accounts)** support via the `gmsa` block inside `windows_profile`:
  - `dns_server` — AD domain controller IP reachable from the node pool subnet
  - `root_domain` — AD domain FQDN (e.g. `corp.contoso.com`)
- `enable_windows_node_pools` feature flag — all Windows/gMSA resources gated behind a single boolean, zero cost when `false`
- `windows_profile` variable marked `sensitive = true` to prevent credential exposure in plan output
- Additional Linux node pools support via `linux_node_pools` map variable
- `aad_rbac` variable for Azure AD RBAC configuration with `azure_rbac_enabled` and `admin_group_object_ids`
- `maintenance_window` variable for scheduled AKS upgrade windows
- `enable_secret_store_csi` flag for Key Vault Secrets Store CSI driver
- `oidc_issuer_enabled` + `workload_identity_enabled` flags for federated workload identity
- `acr_id` variable in identity module for optional `AcrPull` role assignment on kubelet identity
- `custom_dns_servers` variable in network module (required for AD/gMSA connectivity)
- `additional_subnets` and `additional_vnet_links` in network module for hub-spoke topologies
- `os_disk_type = "Ephemeral"` on system and Linux node pools for improved IO performance
- `upgrade_settings { max_surge = "33%" }` on all node pools
- `local_account_disabled`, `azure_policy_enabled` feature flags
- Full `outputs.tf` at root and module level
- `terraform.tfvars.example` with annotated production-ready defaults

### Changed
- System node pool autoscaling enabled by default (`auto_scaling_enabled = true`)
- `system_node_pool_min_count` and `system_node_pool_max_count` are now separate variables (previously a single `node_count`)
- `depends_on` on AKS module now explicitly lists both `module.identity` and `module.network`
- `lifecycle.ignore_changes` extended to include `kubernetes_version` to support separate upgrade workflows

### Fixed
- Missing `dominant-baseline` on text elements in prior architecture diagram references
- `only_critical_addons_enabled` correctly set on system pool to enforce taint

---

## [1.0.0] — 2026-01-10

### Added
- Initial three-module split: `identity`, `network`, `aks`
- User-assigned managed identity for AKS control plane and kubelet
- Role assignments: Private DNS Zone Contributor, Network Contributor, Managed Identity Operator
- Private AKS cluster with custom private DNS zone
- Azure CNI Overlay networking (`network_plugin_mode = "overlay"`)
- BYO VNet and subnet support
- Root module orchestrating all three child modules with `depends_on`
- `auto_scaler_profile` stub (basic, no tuning variables exposed)
- `outbound_type = "userDefinedRouting"` default for private cluster egress compatibility

---

## Planned — [1.2.0]

- Azure Monitor / Container Insights integration
- Defender for Containers add-on flag
- Node pool spot instance support (`priority = "Spot"`, eviction policy)
- gMSA `credentialspec` ConfigMap Kubernetes manifest output
- Key Vault data source example for Windows admin password
- Diagnostic settings for AKS control plane logs (to Log Analytics)
