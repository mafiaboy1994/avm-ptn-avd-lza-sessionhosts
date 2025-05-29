// general variables //

variable "location" {
  type        = string
  description = "Location of the Azure Virtual Desktop core resources Resource Group."
  default     = "uksouth"
  validation {
    condition     = can(regex("^[a-zA-Z0-9\\- ]{2,90}$", var.location))
    error_message = "location must be a valid Azure location name (2-90 characters, alphanumeric and hyphens allowed)."
  }      
}

variable "hosts_count"{
    type = number
    default = 0
    description = "Number of Virtual Machines to create in the host pool."
    validation {
      condition     = var.hosts_count >= 0
      error_message = "The number of hosts must be zero or greater."
    }
}

variable "hosts_resource_group" {
  type        = string
  description = "Resource Group Name"
  default     = null  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\-]{2,90}$", var.hosts_resource_group)) || var.hosts_resource_group == null
    error_message = "hosts_resource_group must be a valid Azure resource group name (2-90 characters, alphanumeric and hyphens allowed)."
  }
}

variable "hosts_name_prefix"{
    type = string
    description = "Prefix for the Virtual Machine names in the host pool."
    default = "avd-host"
    validation {
      condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\-]{2,63}$", var.hosts_name_prefix))
      error_message = "hosts_name_prefix must be a valid Azure resource name (2-63 characters, alphanumeric and hyphens allowed)."
    }
}

variable "host_pool_name"{
    type = string
    description = "Name of the Azure Virtual Desktop Host Pool."  
    default = null
    validation {
      condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\-]{2,63}$", var.host_pool_name)) || var.host_pool_name == null
      error_message = "host_pool_name must be a valid Azure resource name (2-63 characters, alphanumeric and hyphens allowed)."
    }
}

variable "registrationInfoToken"{
    type = string
    description = "Registration token for the host pool, used to register VMs."
    default = null
}



variable "hosts_sku"{
    type = string
    default = "Standard_DS4_v2" # Default value for VM SKU
    description = "SKU for the Virtual Machine, e.g., Standard_DS4_v2, Standard_E8s_v3, etc."
    validation {
      condition     = can(regex("^Standard_DS[0-9]+_v[0-9]+$", var.hosts_sku)) || can(regex("^Standard_E[0-9]+s_v[0-9]+$", var.hosts_sku))
      error_message = "hosts_sku must be a valid Azure VM SKU, e.g., Standard_DS4_v2 or Standard_E8s_v3."
    }
}

variable "hosts_os_disk_size"{
    type = number
    default = 128 # Default value for OS Disk Size in GB
    description = "Size of the OS Disk for the Virtual Machine in GB."
    validation {
      condition     = var.hosts_os_disk_size >= 30 && var.hosts_os_disk_size <= 2048
      error_message = "hosts_os_disk_size must be between 30 and 2048 GB."
    }
}

variable "hosts_os_disk_type"{
    type = string
    default = "Premium_LRS" # Default value for OS Disk Type
    description = "Type of OS Disk for the Virtual Machine, e.g., Premium_LRS, StandardSSD_LRS, etc."
    validation {
      condition     = contains(["Premium_LRS", "StandardSSD_LRS", "Standard_LRS"], var.hosts_os_disk_type)
      error_message = "hosts_os_disk_type must be one of Premium_LRS, StandardSSD_LRS, or Standard_LRS."
    }
}

variable "hosts_admin_username" {
  type        = string
  description = "Virtual Machine Admin Username"
  validation {
    condition     = length(var.hosts_admin_username) >= 3
    error_message = "The admin username must be at least 3 characters long."
  }
}

variable "domain_join_type" {
  type = string
  description = "Type of Domain to join the VM to; can be 'entra' for Entra ID join or 'AD' for Active Directory join."
  validation {
    condition     = contains(["entra", "AD"], var.domain_join_type)
    error_message = "domain_join_type must be either 'entra' or 'AD'."
  }
}

variable "hosts_admin_password" {
  type        = string
  description = "Virtual Machine Admin Password"
  sensitive   = true
  validation {
    condition     = length(var.hosts_admin_password) >= 12
    error_message = "The admin password must be at least 12 characters long."
  }
}


variable "shared_image_id" {
  type = string
  description = "Shared Image ID to be used for the Virtual Machines in the host pool."
  default = null  
  validation {
    condition     = can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Compute/images/.+", var.shared_image_id)) || var.shared_image_id == null
    error_message = "shared_image_id must be a valid Shared Image ID or null."
  }
}

variable "virtual_desktop_host_pool_subnet_configuration"{
    type = object({
        virtual_network_name    = string
        virtual_network_rg_name = string
        subnet_name             = string
        subnet_address_prefixes = list(string)
    })
    description = "Configuration for the Virtual Desktop Host Pool Subnet."
    default = {
        virtual_network_name    = null
        virtual_network_rg_name = null
        subnet_name             = null
        subnet_address_prefixes = []
    }   
    validation {
      condition = var.virtual_desktop_host_pool_subnet_configuration.virtual_network_name != null && var.virtual_desktop_host_pool_subnet_configuration.virtual_network_rg_name != null && var.virtual_desktop_host_pool_subnet_configuration.subnet_name != null && length(var.virtual_desktop_host_pool_subnet_configuration.subnet_address_prefixes) > 0
      error_message = "All fields in virtual_desktop_host_pool_subnet_configuration must be provided and subnet_address_prefixes must not be empty."
    } 
}


variable "tags" {
  type = map(string)
  default = {}
  description = "A map of tags to assign to the resources."
  validation {
    condition     = alltrue([for v in values(var.tags) : can(regex("^[a-zA-Z0-9_\\-]+$", v))])
    error_message = "All tag values must consist of alphanumeric characters, underscores, or hyphens."
  }
}

variable "kv_id"{
  type = string
  description = "Key Vault ID where secrets are stored."
  default = null
  validation {
    condition     = can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.KeyVault/vaults/.+", var.kv_id)) || var.kv_id == null
    error_message = "kv_id must be a valid Key Vault ID or null."
  }
}

variable "domain_join_password_secret_name"{
  type = string
  description = "Name of Key Vault Secret for Domain Join Password"
  default = null
  validation {
    condition     = var.domain_join_type == "AD" ? var.domain_join_password_secret_name != null : true
    error_message = "domain_join_password_secret_name must be provided if domain_join_type is 'AD'."
  }
}

variable "domain_name" {
  type = string
  description = "Domain Local AD name for joining VM to AD"
  default = null
  validation {
    condition     = var.domain_join_type == "AD" ? var.domain_name != null : true
    error_message = "domain_name must be provided if domain_join_type is 'AD'."
  }
}

variable "domain_ou_path" {
  type = string
  description = "Domain OU Path for joining VM to Local AD"
  default = null
  validation {
    condition     = var.domain_join_type == "AD" ? var.domain_ou_path != null : true
    error_message = "domain_ou_path must be provided if domain_join_type is 'AD'."
  }
}

variable "domain_join_username"{
  type = string
  description = "Domain Username to be used for joining to local AD"
  default = null
  validation {
    condition     = var.domain_join_type == "AD" ? var.domain_join_username != null : true
    error_message = "domain_join_username must be provided if domain_join_type is 'AD'."
  }
}
