// general variables //

variable "location" {
  type        = string
  description = "Location of the Azure Virtual Desktop core resources Resource Group."
}

variable "hosts_count"{
    type = number
    default = 0
}

variable "hosts_resource_group" {
  type        = string
  description = "Resource Group Name"
}

variable "hosts_name_prefix"{
    type = string
}

variable "host_pool_name"{
    type = string
}

variable "registrationInfoToken"{
    type = string
}



variable "hosts_sku"{
    type = string
    default = "Standard_DS4_v2" # Default value for VM SKU
    description = "SKU for the Virtual Machine, e.g., Standard_DS4_v2, Standard_E8s_v3, etc."
}

variable "hosts_os_disk_size"{
    type = number
    default = 128 # Default value for OS Disk Size in GB
    description = "Size of the OS Disk for the Virtual Machine in GB."
}

variable "hosts_os_disk_type"{
    type = string
    default = "Premium_LRS" # Default value for OS Disk Type
    description = "Type of OS Disk for the Virtual Machine, e.g., Premium_LRS, StandardSSD_LRS, etc."
}

variable "hosts_count" {
  type        = number
  description = "Number of Virtual Machines to create in the host pool."
  default     = 1
  validation {
    condition     = var.hosts_count >= 0
    error_message = "The number of hosts must be zero or greater."
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
}

variable "virtual_desktop_host_pool_subnet_configuration"{
    type = object({
        virtual_network_name    = string
        virtual_network_rg_name = string
        subnet_name             = string
        subnet_address_prefixes = list(string)
    })
}


variable "tags" {
  type = map(string)
}

variable "kv_id"{
  type = string
}

variable "domain_join_password_secret_name"{
  type = string
  description = "Name of Key Vault Secret for Domain Join Password"
  default = null
}

variable "domain_name" {
  type = string
  description = "Domain Local AD name for joining VM to AD"
  default = null
}

variable "domain_ou_path" {
  type = string
  description = "Domain OU Path for joining VM to Local AD"
  default = null
}

variable "domain_join_username"{
  type = string
  description = "Domain Username to be used for joining to local AD"
  default = null
}
