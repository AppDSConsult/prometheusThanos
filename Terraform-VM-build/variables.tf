variable "subscription_id" {
  description = "Azure authentication details"
  default     = ""  #Add subscription_id
}

variable "client_id" {
  description = "Azure authentication details"
  default     = ""  #Add client_id
}

variable "client_secret" {
  description = "Azure authentication details"
  default     = ""  #Add client_secret
}

variable "tenant_id" {
  description = "Azure authentication details"
  default     = ""  #Add tenant_id
}

variable "vm_count" {
  description = "Number of VMs to deploy"
  default     = 1
}

variable "vm_prefix" {
  description = "Prefix of the name of the VM(s)"
  default =  ""  #Add VM prefix
}

variable "admin_username" {
  description = "Name of the admin account"
  default     = ""  #Add admin name
}

variable "admin_password" {
  default     = ""  #Add admin password
}

variable "region" {
  description = "Region in which to deploy these resources"
  default = "uksouth"   #Add build region
}

variable "resource_group_name" {
  description = "Name of the Resource Group in which to deploy these resources"
  default =  ""  #Add build resource group
}

variable "vm_size" {
  description = "Size of the machine to deploy"
  default     = "Standard_B1s"  #Add size
}

variable "nsg_id" {
  description = "**OPTIONAL**: ID of the NSG to associate the network interface"
  default     = ""
}

variable "managed_disk_type" {
  description = "**OPTIONAL**: If a manged disks are attached this allows for choosing the type. The default value is Standard_LRS"
  default     = "Standard_LRS"
}

variable "existing_subnet_name" {
  description = "Name of the existing subnet to import/associate"
  default =  ""  #Add existing subnet name
}

variable "existing_vnet_name" {
  description = "Name of the existing virtual network to import/associate"
  default =  ""  #Add existing vnet name
}

variable "existing_vnet_rg_name" {
  description = "Resource Group ame of the existing virtual network"
  default =  ""  #Add Resource Group of the existing virtual network
}