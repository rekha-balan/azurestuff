resource "azurerm_resource_group" "test" {
  name     = "acctestRG1"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "test" {
  name                   = "acctestaks1"
  location               = "${azurerm_resource_group.test.location}"
  resource_group_name    = "${azurerm_resource_group.test.name}"
  kubernetes_version     = "1.8.2"
  dns_prefix             = "acctestagent1"

  linux_profile {
    admin_username = "acctestuser1"

    ssh_key {
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCkmGD1SkSEGUJT21dlsZrdG4hcJcUby/TzwyBtD3v7pXmlniMDflT4gJuFjrXlubZM8Fy/Y7xFabYPaaajtJqWKRs05La10NW1aUgkfT1/1R3N095qXd5hgaYIsfscEy4cd451Iv5gplyXcrkA9dykREhe1oqXnx4RMn2Xrlh5Qw5haQ95LpxfhP3Qhjv2x4l6fny+8EPnF8N0EqZjRHSHIp10JwhZdsVOiIj462yr/9VTRyDtVR9jIO/4c0RyfNvoans9JKrrjIYVWjKOSl83KgYW2gi+3J0nifKjH5b3Zv1W0hytp702mP+goDqJhzO6sSDfuexyLopPU4pVCwoRH3649wgOgA6qcDDh6gKuaz+axT4g2uW/c4K1kiiOQKqOp7Rqj1A1Q2qC62vw3W7iwHwpif+k5ZfNvFLaL8nMplWug2KsS251YsGjXjXgv+H3rgjA1y5vNsTP7uHdQfV3TO1g8+T5hTVxLJP519wT9mkywQdyAyeV27RhIZITGzKF5IBBEAmVvTzPuOJaxqORTxJIOOJBcZ7r1RHTq1xXIDli9Vg12tgo/hRhnmNbpp+qssXi6PCgAswodtcFms1MFt0sPOFyyTpY9n6PTaaYtHrt1VyogdAvL/FbPwqM6utSeYBYxLW6VcRIsEhCAhyx1dlpQHtUglP16tOF454Wbw== jminck@gmail.com"
    }
  }

  agent_pool_profile {
    name              = "default"
    count             = 1
    vm_size           = "Standard_A0"
    os_type           = "Linux"
    os_disk_size_gb   = 30
  }

  service_principal {
 
#  "appId": "fdc1a2fe-91c5-48a6-9304-ddd743c40eda",
#  "displayName": "azure-cli-2018-03-19-20-27-13",
# "name": "http://azure-cli-2018-03-19-20-27-13",
#  "password": "3286f64a-dfc8-4acd-ac5c-ade180b653e3b",
#  "tenant": "72417a91-abe7-4f18-ba6d-aef099a10f2a"

    client_id     = "fda1a2fe-91c5-48a6-9304-7f7743c40eda"
    client_secret = "328da64a-dfec8-4fec-fe5c-68fefb653e3b"
  }

  tags {
    Environment = "Production"
  }
}
