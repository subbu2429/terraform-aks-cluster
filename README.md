# AKS Terraform Module

Production-grade Terraform module for provisioning a **private AKS cluster** on Azure with:

- Three-module separation: `identity` / `network` / `aks`
- User-assigned managed identities (control plane + kubelet)
- Azure CNI Overlay networking
- Custom private DNS zone
- Cluster autoscaler profile (fully tunable)
- Optional Windows node pools with gMSA support
- AAD RBAC, OIDC workload identity, Key Vault CSI, Azure Policy

---

## Architecture

```
root module
├── module/network      VNet · Subnet · Private DNS Zone · VNet Link
├── module/identity     Control plane identity · Kubelet identity · Role assignments
└── module/aks          AKS cluster · System pool · Linux pools · Windows pool (opt)
```

**Dependency order:** `network` → `identity` → `aks`

The identity module requires the DNS zone ID and subnet ID from the network module to
create role assignments. The AKS module then consumes outputs from both. A `depends_on`
on the AKS module ensures all role assignments propagate in Azure AD before the cluster
PUT request is submitted — without it you risk intermittent `AuthorizationFailed` errors.

```
┌──────────────────┐     subnet_id, dns_zone_id     ┌──────────────────┐
│  module/network  │ ─────────────────────────────► │ module/identity  │
│                  │                                 │                  │
│ · VNet           │                                 │ · Control plane  │
│ · Subnet         │                                 │   identity       │
│ · Private DNS    │                                 │ · Kubelet        │
│ · VNet Link      │                                 │   identity       │
└──────────────────┘                                 │ · Role           │
         │                                           │   assignments    │
         │  subnet_id                                └──────────────────┘
         │  dns_zone_id                                       │
         │                            identity_ids, kubelet_* │
         └──────────────────┬─────────────────────────────────┘
                            ▼
                  ┌──────────────────┐
                  │   module/aks     │
                  │                  │
                  │ · Private cluster│
                  │ · CNI Overlay    │
                  │ · System pool    │
                  │ · Linux pools    │
                  │ · Windows pool   │
                  │   (optional)     │
                  │ · Autoscaler     │
                  │   profile        │
                  │ · gMSA (opt)     │
                  └──────────────────┘
```

---

## Requirements

| Tool      | Version  |
|-----------|----------|
| Terraform | >= 1.5.0 |
| azurerm   | ~> 4.0   |

---

## Usage

```hcl
module "network" {
  source = "./modules/network"

  cluster_name          = "my-aks-prod"
  resource_group_name   = azurerm_resource_group.this.name
  location              = "eastus"
  vnet_address_space    = ["10.0.0.0/8"]
  node_pool_subnet_cidr = ["10.1.0.0/16"]
  private_dns_zone_name = "privatelink.eastus.azmk8s.io"
}

module "identity" {
  source = "./modules/identity"

  cluster_name        = "my-aks-prod"
  resource_group_name = azurerm_resource_group.this.name
  location            = "eastus"
  private_dns_zone_id = module.network.private_dns_zone_id
  subnet_id           = module.network.node_pool_subnet_id
}

module "aks" {
  source = "./modules/aks"

  cluster_name               = "my-aks-prod"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = "eastus"
  kubernetes_version         = "1.29"
  private_dns_zone_id        = module.network.private_dns_zone_id
  node_pool_subnet_id        = module.network.node_pool_subnet_id
  control_plane_identity_id  = module.identity.control_plane_identity_id
  kubelet_identity_id        = module.identity.kubelet_identity_id
  kubelet_identity_client_id = module.identity.kubelet_identity_client_id
  kubelet_identity_object_id = module.identity.kubelet_identity_object_id
  dns_service_ip             = "10.2.0.10"
  service_cidr               = "10.2.0.0/16"
  pod_cidr                   = "10.244.0.0/16"

  depends_on = [module.identity, module.network]
}
```

See [`terraform.tfvars.example`](./terraform.tfvars.example) for a full production-ready configuration.

---

## Module: identity

Creates two user-assigned managed identities and all required role assignments.

| Resource | Purpose |
|---|---|
| `azurerm_user_assigned_identity.control_plane` | AKS control plane identity |
| `azurerm_user_assigned_identity.kubelet` | Kubelet/node identity |
| `azurerm_role_assignment.dns_contributor` | Control plane → Private DNS Zone Contributor |
| `azurerm_role_assignment.network_contributor` | Control plane → Network Contributor on subnet |
| `azurerm_role_assignment.managed_identity_operator` | Control plane → Managed Identity Operator on kubelet identity |
| `azurerm_role_assignment.acr_pull` | Kubelet → AcrPull (optional, when `acr_id` is set) |

### Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | `string` | — | Cluster name prefix |
| `resource_group_name` | `string` | — | Resource group |
| `location` | `string` | — | Azure region |
| `private_dns_zone_id` | `string` | — | DNS zone ID for role assignment |
| `subnet_id` | `string` | — | Subnet ID for role assignment |
| `acr_id` | `string` | `null` | Optional ACR ID for AcrPull |
| `tags` | `map(string)` | `{}` | Resource tags |

### Outputs

| Name | Description |
|---|---|
| `control_plane_identity_id` | Resource ID of control plane identity |
| `control_plane_identity_principal_id` | Principal ID |
| `kubelet_identity_id` | Resource ID of kubelet identity |
| `kubelet_identity_client_id` | Client ID |
| `kubelet_identity_object_id` | Object ID |

---

## Module: network

| Resource | Purpose |
|---|---|
| `azurerm_virtual_network` | Main VNet |
| `azurerm_subnet.node_pool` | Primary node pool subnet |
| `azurerm_subnet.additional` | Optional extra subnets (for_each) |
| `azurerm_private_dns_zone` | AKS private DNS zone |
| `azurerm_private_dns_zone_virtual_network_link` | Links VNet to DNS zone |

### Key inputs

| Name | Default | Description |
|---|---|---|
| `vnet_address_space` | `["10.0.0.0/8"]` | VNet CIDR |
| `node_pool_subnet_cidr` | `["10.1.0.0/16"]` | Node pool subnet CIDR |
| `private_dns_zone_name` | — | e.g. `privatelink.eastus.azmk8s.io` |
| `custom_dns_servers` | `[]` | AD DC IPs (required for gMSA) |
| `additional_subnets` | `{}` | Extra subnets map |
| `additional_vnet_links` | `{}` | Hub VNet links map |

---

## Module: aks

### Autoscaler profile

All fields are optional. Defaults are conservative and production-safe.

| Variable | Default | Description |
|---|---|---|
| `expander` | `random` | Scale-up strategy: `random`, `least-waste`, `most-pods`, `priority` |
| `balance_similar_node_groups` | `false` | Distribute nodes evenly across similar pools |
| `scale_down_unneeded` | `10m` | How long a node must be underutilised before scale-down |
| `scale_down_utilization_threshold` | `0.5` | CPU/memory utilisation below which a node is considered for removal |
| `scale_down_delay_after_add` | `10m` | Cool-down after a scale-up event |
| `skip_nodes_with_local_storage` | `true` | Protect nodes with emptyDir/hostPath volumes |
| `skip_nodes_with_system_pods` | `true` | Protect nodes running kube-system pods |

### Windows + gMSA

Enable with `enable_windows_node_pools = true`.

```hcl
windows_profile = {
  admin_username = "winadmin"
  admin_password = var.windows_admin_password  # sourced from Key Vault

  gmsa = {
    dns_server  = "10.0.0.4"         # AD DC IP (must be reachable from node subnet)
    root_domain = "corp.contoso.com"
  }
}

windows_node_pool = {
  vm_size         = "Standard_D8s_v5"
  min_count       = 1
  max_count       = 5
  node_taints     = ["os=windows:NoSchedule"]
}
```

**gMSA prerequisites:**
1. Node pool subnet must have network line-of-sight to the AD DC on ports 88 (Kerberos), 389 (LDAP), and 445 (SMB).
2. `custom_dns_servers` in the network module must point to the AD DC so Windows nodes resolve AD records.
3. A `credentialspec` ConfigMap must be deployed into the cluster before Windows workloads can use gMSA — see [Microsoft docs](https://learn.microsoft.com/en-us/azure/aks/use-group-managed-service-accounts).
4. The `admin_password` must meet Windows complexity requirements (12+ chars, upper, lower, digit, symbol).

**Node taint:** The default taint `os=windows:NoSchedule` prevents Linux workloads from landing on Windows nodes. Windows workloads must add a matching toleration and `nodeSelector: kubernetes.io/os: windows`.

### Feature flags

| Variable | Default | Description |
|---|---|---|
| `local_account_disabled` | `true` | Disable built-in `clusterAdmin` / `clusterUser` kubeconfig credentials |
| `azure_policy_enabled` | `true` | Enable Azure Policy add-on for governance |
| `oidc_issuer_enabled` | `true` | Enable OIDC issuer + workload identity |
| `enable_secret_store_csi` | `false` | Enable Secrets Store CSI driver for Key Vault integration |

---

## Quick start

```bash
# 1. Copy and edit variables
cp terraform.tfvars.example terraform.tfvars

# 2. Initialise
terraform init

# 3. Preview
terraform plan -out=tfplan

# 4. Apply
terraform apply tfplan

# 5. Get kubeconfig (cluster is private — run from within VNet or via jump host)
terraform output -raw kube_config_raw > ~/.kube/config
```

---

## Security considerations

- `local_account_disabled = true` enforces AAD authentication — no static credentials
- `private_cluster_enabled = true` — API server is not reachable from the public internet
- `admin_password` for Windows nodes is marked `sensitive = true` — never stored in plan output
- Role assignments follow least-privilege: each identity receives only the roles it needs
- `outbound_type = "userDefinedRouting"` — egress is controlled via your own UDR/firewall
- Enable `enable_secret_store_csi = true` and reference Key Vault secrets rather than environment variables for application secrets

---

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).

---

## License

MIT
