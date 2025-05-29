
# 🚀 Azure Virtual Desktop Session Host Module

This Terraform module automates the deployment of Azure Virtual Desktop (AVD) session host virtual machines (VMs), including domain join configuration, VM extensions, and required Key Vault secret management.

---

## 📦 Features

- Deploys a specified number of AVD session hosts.
- Supports either **Active Directory (AD)** or **Entra ID (formerly Azure AD)** domain join.
- Configures required VM extensions for AVD host pool registration and domain joining.
- Integrates with Azure Key Vault to manage sensitive secrets securely.
- Automatically assigns Key Vault permissions to VMs.
- Uses Shared Image Gallery or Marketplace images.

---

## 📁 Structure

- `main.tf`: Core resources (VMs, NICs, extensions, Key Vault, etc.)
- `variables.tf`: Input variables with validation.
- `locals.tf`: Computed values and conditional logic.

---

## 🔧 Usage

```hcl
module "avd_session_hosts" {
  source = "./path-to-module"

  location                               = "eastus"
  hosts_count                            = 3
  hosts_resource_group                   = "rg-avd-hosts"
  hosts_name_prefix                      = "avdhost"
  host_pool_name                         = "my-avd-pool"
  registrationInfoToken                  = "eyJ0eXAiOiJKV1QiLCJhb..."
  hosts_sku                              = "Standard_DS4_v2"
  hosts_os_disk_size                     = 128
  hosts_os_disk_type                     = "Premium_LRS"
  hosts_admin_username                   = "azureadmin"
  hosts_admin_password                   = "SuperSecurePassword123!"
  domain_join_type                       = "AD" # or "entra"
  domain_join_password_secret_name       = "avd-join-secret"
  domain_name                            = "corp.local"
  domain_ou_path                         = "OU=AVD,DC=corp,DC=local"
  domain_join_username                   = "CORP\\joinaccount"
  shared_image_id                        = null
  kv_id                                  = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.KeyVault/vaults/xxx"
  virtual_desktop_host_pool_subnet_configuration = {
    virtual_network_name    = "vnet-avd"
    virtual_network_rg_name = "rg-network"
    subnet_name             = "snet-avd"
    subnet_address_prefixes = ["10.0.0.0/24"]
  }
  tags = {
    environment = "dev"
    owner       = "team-avd"
  }
}
```

---

## 🧠 Domain Join Logic

- **Active Directory (AD)** join is triggered when:
  - `domain_join_type` = `"AD"`
  - `domain_join_password_secret_name` is provided
- A separate `JsonADDomainExtension` is attached to each VM for AD join.
- `Entra ID` join uses DSC extension with Entra-specific properties.

---

## 🔐 Key Vault Integration

- Secrets like admin passwords and AD join passwords are pulled from Azure Key Vault.
- Each VM is granted `Key Vault Secrets Officer` and `Key Vault Crypto Service Encryption User` roles.

---

## 🔄 Conditional Logic

- Resources are only created when required:
  - Domain join extension is created only if `domain_join_type == "AD"`.
  - Secret data sources use `count` to avoid evaluation errors.
  - `locals` safely compute values using guards for optional inputs.

---

## 🛡️ Validation & Defaults

- Built-in validation ensures inputs like passwords and usernames meet minimum standards.
- Defaults provided for common settings like VM SKU and OS disk size.

---

## 🧪 Testing

Run the following to test and validate your plan:

```bash
terraform init
terraform plan
terraform apply
```

---

## 📎 Notes

- Ensure the provided Key Vault has the necessary secrets and permissions.
- If using a Shared Image Gallery image, set `shared_image_id` to the correct ID; otherwise, the module uses a default Marketplace image.
- AVD registration token must be valid and active when deploying.
