variable "vmcount" {
  default = 3 
}

resource "azurerm_resource_group" "test" {
 name     = "acctestrg"
 location = "West US 2"
}

resource "azurerm_virtual_network" "test" {
 name                = "acctvn"
 address_space       = ["10.0.0.0/16"]
 location            = "${azurerm_resource_group.test.location}"
 resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "test" {
 name                 = "acctsub"
 resource_group_name  = "${azurerm_resource_group.test.name}"
 virtual_network_name = "${azurerm_virtual_network.test.name}"
 address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "test" {
 name                         = "publicIPForLB"
 location                     = "${azurerm_resource_group.test.location}"
 resource_group_name          = "${azurerm_resource_group.test.name}"
 public_ip_address_allocation = "static"
}

resource "azurerm_lb" "test" {
 name                = "loadBalancer"
 location            = "${azurerm_resource_group.test.location}"
 resource_group_name = "${azurerm_resource_group.test.name}"

 frontend_ip_configuration {
   name                 = "publicIPAddress"
   public_ip_address_id = "${azurerm_public_ip.test.id}"
 }
}

resource "azurerm_network_security_group" "temyterraformpublicipnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "${azurerm_resource_group.test.location}"
    resource_group_name = "${azurerm_resource_group.test.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Terraform Demo"
    }
}

resource "azurerm_lb_backend_address_pool" "test" {
 resource_group_name = "${azurerm_resource_group.test.name}"
 loadbalancer_id     = "${azurerm_lb.test.id}"
 name                = "BackEndAddressPool"
}

resource "azurerm_network_interface" "test" {
 count               = "${var.vmcount}" 
 name                = "acctni${count.index}"
 location            = "${azurerm_resource_group.test.location}"
 resource_group_name = "${azurerm_resource_group.test.name}"
 network_security_group_id = "${azurerm_network_security_group.temyterraformpublicipnsg.id}"

 ip_configuration {
   name                          = "testConfiguration"
   subnet_id                     = "${azurerm_subnet.test.id}"
   private_ip_address_allocation = "dynamic"
   load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.test.id}"]
   public_ip_address_id = "${element(azurerm_public_ip.vmfe.*.id, count.index)}" 
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

resource "azurerm_availability_set" "avset" {
 name                         = "avset"
 location                     = "${azurerm_resource_group.test.location}"
 resource_group_name          = "${azurerm_resource_group.test.name}"
 platform_fault_domain_count  = 2
 platform_update_domain_count = "${var.vmcount}"
 managed                      = true
}

resource "azurerm_public_ip" "vmfe" {
   count               = "${var.vmcount}"
   name = "PublicIPacctvm${count.index}"
   resource_group_name = "${azurerm_resource_group.test.name}"
   public_ip_address_allocation = "static"
   location            = "${azurerm_resource_group.test.location}"
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

resource "azurerm_virtual_machine" "test" {
 count                 = "${var.vmcount}"
 name                  = "acctvm${count.index}"
 location              = "${azurerm_resource_group.test.location}"
 availability_set_id   = "${azurerm_availability_set.avset.id}"
 resource_group_name   = "${azurerm_resource_group.test.name}"
 network_interface_ids = [
                        "${element(azurerm_network_interface.test.*.id, count.index)}"
                        ]
 vm_size               = "Standard_B1s"

 # Uncomment this line to delete the OS disk automatically when deleting the VM
 # delete_os_disk_on_termination = true

 # Uncomment this line to delete the data disks automatically when deleting the VM
 # delete_data_disks_on_termination = true

 storage_image_reference {
   publisher = "Canonical"
   offer     = "UbuntuServer"
   sku       = "16.04-LTS"
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
   computer_name  = "acctvm${count.index}"
   admin_username = "testadmin"
   admin_password = "Password1234!"
 }

 os_profile_linux_config {
   disable_password_authentication = false
          ssh_keys {
            path     = "/home/testadmin/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8DWNQmpCYQ8zl12dhWPkGpeU2fQXmBB3harzAXT65Tsa+owW9OaB6xNftLjqCzd/7I7k9WIGfbsbphcKIXPeIJ6Fnpx9wqy4otXZV3btymwM2z1++cuSKxDLtJuV/8ZbkzbFMesZBc16nmy2vCzN54EZ0vqwGyw/L3X3FajvJCUcrRCk1V4tIdR+EAdSAtBUi7IF71tMMUNY3X/3eAwpu8xvlF8gBKU6ojAbRWYhTf2FS585phNLr9CgAZGwgLQlhAqji1H94JPj4OqGHp/Iet8y1VbsC689Evn3haf+ijveG/bTE4xFYBw1pYjigPIJyfpsBjuwvmNa5H1wo3nvT"
        }
 }

 boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
 }

 tags {
   environment = "staging"
 }
}
