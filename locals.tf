locals {
  # Detect valid shared image
  valid_shared_image_id = (
    var.shared_image_id != null &&
    var.shared_image_id != ""
  ) ? var.shared_image_id : null

  

  # Detect valid secret name for domain join password
  is_valid_secret_name = (
    var.domain_join_password_secret_name != null &&
    var.domain_join_password_secret_name != ""
  )

  # Check domain join type
  is_entra_join = var.domain_join_type == "entra"
  is_ad_join = var.domain_join_type == "AD"

  # dsc_settings = {
  #   modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip"
  #   configurationFunction = "Configuration.ps1\\AddSessionHost"
  #   properties = merge(
  #     {
  #       HostPoolName                        = var.host_pool_name
  #       aadJoin                             = local.is_entra_join
  #       UseAgentDownloadEndpoint            = true
  #       sessionHostConfigurationLastUpdateTime = ""
  #     },
  #     local.is_entra_join ? {
  #       aadJoinPreview = false
  #       mdmId          = "0000000a-0000-0000-c000-000000000000"
  #     } : {
  #       aadJoinPreview = false
  #     }
  #   )
  # }

  dsc_settings = {
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip"
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = merge(
      {
        HostPoolName                        = var.host_pool_name
        aadJoin                             = local.is_entra_join
        UseAgentDownloadEndpoint            = true
        sessionHostConfigurationLastUpdateTime = ""
      },
      local.is_entra_join ? {
        aadJoinPreview = false
        mdmId          = "0000000a-0000-0000-c000-000000000000"
      } : {}
    )
  }


   # Only use the secret if AD join is true and secret exists
  join_domain_password_value = (
    local.is_ad_join && local.is_valid_secret_name
  ) ? data.azurerm_key_vault_secret.domain_join_secret[0].value : null

  join_domain_settings = local.is_ad_join ? {
    Name    = var.domain_name
    OUPath  = var.domain_ou_path
    User    = var.domain_join_username
    Restart = "true"
    Options = "3"
  } : null

  join_domain_protected_settings = (
    local.is_ad_join && local.join_domain_password_value != null
  ) ? {
    Password = local.join_domain_password_value
  } : null



}