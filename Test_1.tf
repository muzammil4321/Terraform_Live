terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.50.0"
    }
  }
}
provider "azurerm" {
  # Configuration options for Azure
 features {} 
client_id = 
tenant_id = 
subscription_id = 
client_secret = 
} 

resource "azurerm_resource_group" "myrg" {
  name     = var.RGName
  location = var.RGLocation
}
# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}
# Create network interface for vm1
resource "azurerm_network_interface" "my_terraform_nic1" {
  name                = "${var.prefix}-nic1"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

depends_on = [
    azurerm_virtual_network.my_terraform_network,
    azurerm_subnet.my_terraform_subnet
  ]
}
# Create network interface for vm2
resource "azurerm_network_interface" "my_terraform_nic2" {
  name                = "${var.prefix}-nic2"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name

  ip_configuration {
    name                          = var.ipconfig
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

depends_on = [
    azurerm_virtual_network.my_terraform_network,
    azurerm_subnet.my_terraform_subnet
  ]
}
# Create Network Security Group and rules


resource "azurerm_storage_account" "my_storage_account" {
  name                     = "${var.prefix}diag5245"
  location                 = azurerm_resource_group.myrg.location
  resource_group_name      = azurerm_resource_group.myrg.name
  account_tier             = var.tier
  account_replication_type = var.Replication
  #allow_blob_public_access = true
}

resource "azurerm_storage_container" "data"{
    name= var.blob
    storage_account_name=azurerm_storage_account.my_storage_account.name
    container_access_type = "blob"
    depends_on = [
      azurerm_storage_account.my_storage_account
    ]
}

resource "azurerm_storage_blob" "IIS_configvm1" {
  name                   = var.IIS1
  storage_account_name   = azurerm_storage_account.my_storage_account.name
  storage_container_name = azurerm_storage_container.data.name
  type                   = "Block"
  source                 = "h.ps1"
   depends_on=[azurerm_storage_container.data]
}

resource "azurerm_storage_blob" "IIS_configvm2" {
  name                   = var.IIS2
  storage_account_name   = azurerm_storage_account.my_storage_account.name
  storage_container_name = azurerm_storage_container.data.name
  type                   = "Block"
  source                 = "h1.ps1"
   depends_on=[azurerm_storage_container.data]
}
# Create virtual machine1
resource "azurerm_windows_virtual_machine" "main" {
  name                  = "${var.prefix}-vm1"
  admin_username        = var.username
  admin_password        = var.password
  location              = azurerm_resource_group.myrg.location
  resource_group_name   = azurerm_resource_group.myrg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic1.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
 depends_on = [
    azurerm_network_interface.my_terraform_nic1
      ]
    
}

# Create virtual machine2
resource "azurerm_windows_virtual_machine" "mains" {
  name                  = "${var.prefix}-vm2"
  admin_username        = var.username
  admin_password        = var.password
  location              = azurerm_resource_group.myrg.location
  resource_group_name   = azurerm_resource_group.myrg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic2.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
 depends_on = [
    azurerm_network_interface.my_terraform_nic2
      ]
    
}

 #Install IIS web server to the virtual machine1
resource "azurerm_virtual_machine_extension" "web_server_install" {
 name                       = "${var.prefix}-wsi"
virtual_machine_id         = azurerm_windows_virtual_machine.main.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true
  settings = <<SETTINGS
    {
      "fileUris": ["https://${azurerm_storage_account.my_storage_account.name}.blob.core.windows.net/data/IIS_Configvm1.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Configvm1.ps1"    
    }
  SETTINGS
}
 #Install IIS web server to the virtual machine2
resource "azurerm_virtual_machine_extension" "web_server_install1" {
 name                       = "${var.prefix}-wsi"
virtual_machine_id         = azurerm_windows_virtual_machine.mains.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true
  settings = <<SETTINGS
    {
      "fileUris": ["https://${azurerm_storage_account.my_storage_account.name}.blob.core.windows.net/data/IIS_Configvm2.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Configvm2.ps1"    
    }
  SETTINGS
}

resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
   security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Connect the security group to the network interface
resource "azurerm_subnet_network_security_group_association" "nsgasso" {
  subnet_id      = azurerm_subnet.my_terraform_subnet.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
depends_on = [
  azurerm_network_security_group.my_terraform_nsg
]
}

resource "azurerm_public_ip" "myip" {
  name                = var.publicip
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  allocation_method   = "Static"
  sku =  "Standard"
}
resource "azurerm_lb" "loadbalancer" {
  name                = "TestLoadBalancer"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  sku =  "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.myip.id
  }
}

resource "azurerm_lb_backend_address_pool" "mypool" {
  loadbalancer_id =  azurerm_lb.loadbalancer.id
  name =  "backendpool"
  depends_on = [
    azurerm_lb.loadbalancer
  ]
}

resource "azurerm_lb_backend_address_pool_address" "poola" {
  name                    = "examplepoola"
  backend_address_pool_id = azurerm_lb_backend_address_pool.mypool.id
  virtual_network_id      = azurerm_virtual_network.my_terraform_network.id
  ip_address              = azurerm_network_interface.my_terraform_nic1.private_ip_address
  depends_on = [
    azurerm_lb_backend_address_pool.mypool
  ]
}
resource "azurerm_lb_backend_address_pool_address" "poolb" {
  name                    = "poolb"
  backend_address_pool_id = azurerm_lb_backend_address_pool.mypool.id
  virtual_network_id      = azurerm_virtual_network.my_terraform_network.id
  ip_address              = azurerm_network_interface.my_terraform_nic2.private_ip_address
   depends_on = [
    azurerm_lb_backend_address_pool.mypool
  ]
}
resource "azurerm_lb_probe" "myprobe" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "probeA"
  port            = 80
}

resource "azurerm_lb_rule" "myrule" {
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.mypool.id]
  probe_id = azurerm_lb_probe.myprobe.id
}

output "azurerm_public_ip" { 
  description = "My Azure public ip address" 
  value = azurerm_public_ip.myip.ip_address
} 
