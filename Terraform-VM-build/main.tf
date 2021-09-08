
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}
/*
#Create new virtual network
resource "azurerm_virtual_network" "suse-vnet" {
  name                = "suse-vnet"
  address_space       = ["10.0.7.0/24"]
  location            = var.region
  resource_group_name = var.resource_group_name
}
#Create new subnet
resource "azurerm_subnet" "suse-subnet" {
  name                 = "suse-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.suse-vnet.name
  address_prefixes     = ["10.0.7.0/24"]
}
*/

#Import existing vnet/subnet
data "azurerm_subnet" "dsubnet" {
  name                 = var.existing_subnet_name
  virtual_network_name = var.existing_vnet_name
  resource_group_name  = var.existing_vnet_rg_name
}

#Create public IP - remove if not needed
resource "azurerm_public_ip" "suse-pip" {
  count               = var.vm_count
  name                = "${var.vm_prefix}-${count.index + 1}-pip"
  location            = var.region
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

#Create network interface 
resource "azurerm_network_interface" "suse-nwi" {
  count               = var.vm_count
  name                = "${var.vm_prefix}-${count.index + 1}-nic"
  location            = var.region
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${var.vm_prefix}-${count.index + 1}-nic-01"
    subnet_id                     = data.azurerm_subnet.dsubnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.suse-pip.*.id[count.index] #Remove if public IP not needed
  }

}

/*
#Associate existing NSG
resource "azurerm_network_interface_security_group_association" "NSG" {
count                     = var.rdsh_count
network_interface_id      = azurerm_network_interface.suse-nwi.*.id[count.index]
network_security_group_id = var.nsg_id}
*/

#Create VM
resource "azurerm_virtual_machine" "main" {
  count                 = var.vm_count
  name                  = "${var.vm_prefix}-${count.index + 1}"
  location              = var.region
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.suse-nwi.*.id[count.index]]
  vm_size               = var.vm_size
  #availability_set_id   = azurerm_availability_set.main.id

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  #Azure image details
  storage_image_reference {
    #id = var.vm_image_id != "" ? var.vm_image_id : ""
    #publisher = "${var.vm_image_id == "" ? var.vm_publisher : ""}"
    #offer     = "${var.vm_image_id == "" ? var.vm_offer : ""}"
    #sku       = "${var.vm_image_id == "" ? var.vm_sku : ""}"
    #version   = "${var.vm_image_id == "" ? var.vm_version : ""}"

    publisher = "suse"
    offer     = "sles-15-sp3-byos"
    sku       = "gen1"
    version   = "latest"

  }

  storage_os_disk {
    name = "${lower(var.vm_prefix)}-${count.index + 1}"
    #caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.managed_disk_type
    #disk_size_gb      = var.vm_storage_os_disk_size
  }

  os_profile {
    computer_name  = "${var.vm_prefix}-${count.index + 1}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}

#Install Powershell, OMI, DSC
resource "azurerm_virtual_machine_extension" "dsc" {
  count                = var.vm_count
  name                 = "${var.vm_prefix}-${count.index + 1}-dsc"
  virtual_machine_id   = azurerm_virtual_machine.main.*.id[count.index]
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {      
        "script": "${base64encode(file("script.sh"))}"
    }
SETTINGS

}




