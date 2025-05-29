data "azurerm_client_config" "current" {}

# data "azurerm_key_vault_secret" "domain_join_secret"{
#   count = var.domain_join_password_secret_name ? 1 : 0
#   name = var.domain_join_password_secret_name
#   key_vault_id = var.kv_id
# }


data "azurerm_key_vault_secret" "domain_join_secret" {
  count        = local.is_valid_secret_name ? 1 : 0
  name  = var.domain_join_password_secret_name
  key_vault_id = var.kv_id
}

 resource "azurerm_key_vault_secret" "admin_password" {
  count = var.hosts_count

  key_vault_id = var.kv_id
  #name         = coalesce("${var.avd_host_host_pool_name}-${var.avd_host_vm_admin_username}-password")
  name            = coalesce("${var.hosts_name_prefix}-${count.index+1}-${var.hosts_admin_username}-password")
  value           = var.hosts_admin_password
  content_type    = null
  expiration_date = timeadd(timestamp(), "720h") # 30 Days
  not_before_date = timestamp()
  #tags         = var.tags
  lifecycle {
    ignore_changes = [ 
      expiration_date,
      not_before_date
     ]
  }
}

resource "azurerm_network_interface" "avd_host_vm_nic" {
  count = var.hosts_count
  name                = "nic-${var.hosts_name_prefix}-${count.index+1}"
  resource_group_name = var.hosts_resource_group
  location            = var.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.virtual_desktop_host_pool_subnet_configuration.virtual_network_rg_name}/providers/Microsoft.Network/virtualNetworks/${var.virtual_desktop_host_pool_subnet_configuration.virtual_network_name}/subnets/${var.virtual_desktop_host_pool_subnet_configuration.subnet_name}"
    private_ip_address_allocation = "Dynamic"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_role_assignment" "kv_rights" {
  count = var.hosts_count
  principal_id         = azurerm_windows_virtual_machine.avd_host_vm[count.index].identity[0].principal_id
  scope                = var.kv_id
  role_definition_name = "Key Vault Secrets Officer"
  lifecycle {
    ignore_changes = [ 
      principal_id
     ]
  }
  
}


resource "azurerm_role_assignment" "sa_cmk" {
  count = var.hosts_count
  principal_id         = azurerm_windows_virtual_machine.avd_host_vm[count.index].identity[0].principal_id
  scope                = var.kv_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  lifecycle {
    ignore_changes = [ 
      principal_id
     ]
  }
}


resource "azurerm_windows_virtual_machine" "avd_host_vm" {
  count = var.hosts_count
  resource_group_name = var.hosts_resource_group
  location            = var.location

  name                       = "${var.hosts_name_prefix}${count.index+1}"
  size                       = var.hosts_sku
  enable_automatic_updates   = true
  encryption_at_host_enabled = true
  network_interface_ids = [
    azurerm_network_interface.avd_host_vm_nic[count.index].id
  ]
  provision_vm_agent = true
  admin_username     = var.hosts_admin_username
  admin_password     = azurerm_key_vault_secret.admin_password[count.index].value
  boot_diagnostics {
    storage_account_uri = null
  }
  os_disk {
    name                 = "disk-osdisk-${var.hosts_name_prefix}${count.index+1}"
    caching              = "ReadWrite"
    storage_account_type = var.hosts_os_disk_type
    disk_size_gb         = var.hosts_os_disk_size
  }

  #vm_agent_platform_updates_enabled = true
  #patch_assessment_mode             = "AutomaticByPlatform"
  patch_mode = "AutomaticByOS"
  vm_agent_platform_updates_enabled = true

  identity {
    type = "SystemAssigned"
  }

  # source_image_reference {
  #   publisher = "MicrosoftWindowsDesktop"
  #   offer     = "windows-ent-cpc"
  #   sku       = "win11-22h2-ent-cpc-m365"
  #   version   = "latest"
  # }

  dynamic "source_image_reference" {
    for_each = local.valid_shared_image_id == null ? [1] : []
    content {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "windows-ent-cpc"
      sku       = "win11-22h2-ent-cpc-m365"
      version   = "latest"
    }
  }

  source_image_id = local.valid_shared_image_id


  depends_on = [
    azurerm_network_interface.avd_host_vm_nic
  ]

  lifecycle {
    ignore_changes = [
      tags,
      identity,
      vm_agent_platform_updates_enabled,
      enable_automatic_updates,
      patch_mode,
      patch_assessment_mode
    ]
  }
}



# AD Join Extension
# resource "azurerm_virtual_machine_extension" "joinDomain" {
#   count                = local.is_ad_join ? var.hosts_count : 0 
#   name                 = "domainJoin"
#   type                 = "JsonADDomainExtension"
#   publisher            = "Microsoft.Compute"
#   type_handler_version = "1.3"
#   virtual_machine_id   = azurerm_windows_virtual_machine.avd_host_vm[count.index].id

#   settings           = jsonencode(local.join_domain_settings)
#   protected_settings = jsonencode(local.join_domain_protected_settings)

#   depends_on = [data.azurerm_key_vault_secret.domain_join_secret]

#   lifecycle {
#     ignore_changes = [settings, protected_settings]
#   }
# }


resource "azurerm_virtual_machine_extension" "joinDomain" {
  count                = local.is_ad_join ? var.hosts_count : 0
  name                 = "domainJoin"
  type                 = "JsonADDomainExtension"
  publisher            = "Microsoft.Compute"
  type_handler_version = "1.3"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_host_vm[count.index].id

  settings           = jsonencode(local.join_domain_settings)
  protected_settings = jsonencode(local.join_domain_protected_settings)

  depends_on = [data.azurerm_key_vault_secret.domain_join_secret]

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}


# AVD Join & Entra ID Join Extension
resource "azurerm_virtual_machine_extension" "avd_host_host_pool_join_dsc" {
  count = var.hosts_count
  name                       = "${var.hosts_name_prefix}${count.index+1}-join-host-pool-dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_host_vm[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings           = jsonencode(local.dsc_settings)
  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${var.registrationInfoToken}"
    }
  }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings, tags, virtual_machine_id]
  }

  depends_on = [
    azurerm_windows_virtual_machine.avd_host_vm
  ]
}


resource "azurerm_virtual_machine_extension" "AADLoginForWindows" {
  count = var.hosts_count
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_host_vm[count.index].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.2"
  auto_upgrade_minor_version = true
  settings                   = <<-SETTINGS
    {
      "mdmId": "0000000a-0000-0000-c000-000000000000"
    }
SETTINGS
  depends_on = [
    azurerm_windows_virtual_machine.avd_host_vm
  ]
  lifecycle {
    ignore_changes = [tags, virtual_machine_id]

  }
}
