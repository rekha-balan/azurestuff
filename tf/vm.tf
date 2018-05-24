
resource "azurerm_resource_group" "test" {
  name     = "acctestrg"
  location = "West US 2"
}

resource "azurerm_public_ip" "test" {
  name                         = "acceptanceTestPublicIp1"
  location                     = "West US 2"
  resource_group_name          = "${azurerm_resource_group.test.name}"
  public_ip_address_allocation = "dynamic"

  tags {
    environment = "Production"
  }
}
resource "azurerm_virtual_network" "test" {
  name                = "acctvn"
  address_space       = ["10.0.0.0/16"]
  location            = "West US 2"
  resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "test" {
  name                 = "acctsub"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "test" {
  name                = "acctni"
  location            = "West US 2"
  resource_group_name = "${azurerm_resource_group.test.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.test.id}"
  }
  
  
}

resource "azurerm_managed_disk" "test" {
  name                 = "datadisk_existing"
  location             = "West US 2"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "5"
}

resource "azurerm_virtual_machine" "test" {
  count                 = 1
  name                  = "acctvm${count.index}"
  location              = "West US 2"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size               = "Standard_B1s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "14.04-LTS"
    version   = "latest"
  }


  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # Optional data disks
  storage_data_disk {
    name              = "datadisk_new"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "5"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.test.name}"
    managed_disk_id = "${azurerm_managed_disk.test.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.test.disk_size_gb}"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

    
  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "staging"
  }
}

resource "azurerm_resource_group" "example" {
 name = "resourceGroup1"
 location = "East US 2"
}

resource "azurerm_automation_account" "example" {
  name                = "terraform"
  location            = "${azurerm_resource_group.example.location}"
  resource_group_name = "${azurerm_resource_group.example.name}"
  sku {
    name = "Basic"
  }
}

resource "azurerm_automation_runbook" "example" {
  name                = "Get-AzureVMTutorial"
  location            = "${azurerm_resource_group.example.location}"
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


resource "azurerm_virtual_machine_extension" "test" {
  name                 = "hostname"
  location             = "West US 2" 
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_machine_name = "acctvm${count.index}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"
#  depends_on = ["azurerm_virtual_machine.test"]

  settings = <<SETTINGS
    {
        "commandToExecute": "ifconfig"
    }
SETTINGS

  tags {
    environment = "Production"
  }
}
