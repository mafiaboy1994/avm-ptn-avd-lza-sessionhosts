resource "random_password" "avd_host_random_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Registration information for the host pool.
resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
  expiration_date = timeadd(timestamp(), "48h")
  hostpool_id     = "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-xxx/providers/Microsoft.DesktopVirtualization/hostPools/prod-avd-pool"
}



module "module_avd_hosts"{
  source = "../../."
  count = 2
  hosts_resource_group = "org-avd-val-apps-uks-rg001-hosts"
  vm_index = count.index
  hosts_name_prefix = "avd-apps-staging"
  hosts_sku = "Standard_DS4_v2"
  hosts_os_disk_size = 128
  hosts_os_disk_type = "Premium_LRS"
  hosts_admin_username = "avdadmin"
  hosts_admin_password = random_password.avd_host_random_password.result
  shared_image_id = "SHARED_IMAGE_ID"
  tags = {
    "created_by" = "Terraform"
    "created_on" = timestamp()
    "environment" = "example1"
    "managed_by" = "AVM"
  }
  location = "uksouth"
  virtual_desktop_host_pool_subnet_configuration = {
    virtual_network_name    = "vnet-010"
    virtual_network_rg_name = "rg-networking-org"
    subnet_name             = "org-avd-val-uks-subnet002"
    subnet_address_prefixes = ["192.168.22.128/25"]
}
  host_pool_name = "hostpool-avd-apps-staging"
  registrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
  domain_join_type  = "entra"
  kv_id = "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-xxxx/providers/Microsoft.KeyVault/vaults/kv-xxxxx"
}
