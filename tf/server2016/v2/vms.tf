variable "vmname" {
  default = "winacctvm"
}

variable "location" {
  default = "West US 2"
}

variable "automationlocation" {
  default = "East US 2"
}

variable "vmcount" {
  default = 2
}

resource "azurerm_resource_group" "test" {
  name     = "winacctestrg"
  location =  "${var.location}"
}

resource "azurerm_virtual_network" "test" {
  name                = "winacctvn"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "test" {
  name                 = "winacctsub"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "test" {
 count               = "${var.vmcount}"
 name                = "winacctni${count.index}"
 location            = "${azurerm_resource_group.test.location}"
 resource_group_name = "${azurerm_resource_group.test.name}"
 network_security_group_id = "${azurerm_network_security_group.temyterraformpublicipnsg.id}"

 ip_configuration {
   name                          = "testConfiguration"
   subnet_id                     = "${azurerm_subnet.test.id}"
   private_ip_address_allocation = "dynamic"
   public_ip_address_id = "${element(azurerm_public_ip.vmfe.*.id, count.index)}"
 }
}

resource "azurerm_public_ip" "vmfe" {
   count               = "${var.vmcount}"
   name = "PublicIPwinacctvm${count.index}"
   resource_group_name = "${azurerm_resource_group.test.name}"
   public_ip_address_allocation = "static"
   location            = "${azurerm_resource_group.test.location}"
}

resource "azurerm_network_security_group" "temyterraformpublicipnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "${azurerm_resource_group.test.location}"
    resource_group_name = "${azurerm_resource_group.test.name}"

    security_rule {
        name                       = "RDP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

        security_rule {
        name                       = "WinRM"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "5986"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Terraform Demo"
    }
}

resource "azurerm_managed_disk" "test" {
 count                = "${var.vmcount}"
 name                 = "datadisk_existing_${count.index}"
 location             = "${azurerm_resource_group.test.location}"
 resource_group_name  = "${azurerm_resource_group.test.name}"
 storage_account_type = "Standard_LRS"
 create_option        = "Empty"
 disk_size_gb         = "1023"
}

resource "azurerm_virtual_machine" "test" {
  name                  = "${var.vmname}${count.index}"
  count               = "${var.vmcount}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.test.name}"
   network_interface_ids = [
                        "${element(azurerm_network_interface.test.*.id, count.index)}"
                        ]
  vm_size               = "Standard_B2s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  provisioner "file" {
    source      = "winrm.ps1"
    destination = "c:/temp/winrm.ps1"

    connection {
      type     = "winrm"
      user     = "testadmin"
      password = "Password1234!"
  }
  }

  provisioner "remote-exec" {

   connection {
      type     = "winrm"
      user     = "testadmin"
      password = "Password1234!"
  }
    inline = [
      "c:/temp/winrm.ps1"
    ]
  }

  # 2008-R2-SP1
  # 2012-R2-Datacenter
  # 2016-Datacenter
  # 2016-Nano-Server
  # 2016-Datacenter-Server-Core

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2012-R2-Datacenter"
    version   = "latest"
  }

 storage_os_disk {
   name              = "myosdisk${count.index}"
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }
 
 # Optional data disks
 storage_data_disk {
   name              = "datadisk_new_${count.index}"
   managed_disk_type = "Standard_LRS"
   create_option     = "Empty"
   lun               = 0
   disk_size_gb      = "1023"
 }

 storage_data_disk {
   name            = "${element(azurerm_managed_disk.test.*.name, count.index)}"
   managed_disk_id = "${element(azurerm_managed_disk.test.*.id, count.index)}"
   create_option   = "Attach"
   lun             = 1
   disk_size_gb    = "${element(azurerm_managed_disk.test.*.disk_size_gb, count.index)}"
 }

  os_profile {
    computer_name  = "${var.vmname}${count.index}"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
 

  os_profile_windows_config {
    }
    
  tags {
    environment = "staging"
  }
}

resource "azurerm_resource_group" "example" {
 name = "resourceGroup1"
 location = "${var.location}"
}

resource "azurerm_automation_account" "example" {
  name                = "terraform"
  location            = "${var.automationlocation}"
  resource_group_name = "${azurerm_resource_group.example.name}"
  sku {
    name = "Basic"
  }
}

resource "azurerm_automation_runbook" "example" {
  name                = "Get-AzureVMTutorial"
  location            = "${var.automationlocation}"
  resource_group_name = "${azurerm_resource_group.example.name}"
  account_name        = "${azurerm_automation_account.example.name}"
  log_verbose         = "true"
  log_progress        = "true"
  description         = "This is an example runbook"
  runbook_type        = "PowerShellWorkflow"
  publish_content_link {
    uri = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
  }
}


resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.test.name}"
    }

    byte_length = 8
}

resource "azurerm_storage_account" "mystorageaccount" {
    name                = "diag${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.test.name}"
    location            = "${azurerm_resource_group.test.location}"
    account_replication_type = "LRS"
    account_tier = "Standard"

    tags {
        environment = "Terraform Demo"
    }
}



