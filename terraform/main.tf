provider "azurerm" {
    version = "~> 2.1.0"
    features {}
}

# Get subscription
data "azurerm_subscription" "current" {}

# Create a resource group
resource "azurerm_resource_group" "pkr_rg" {
    name = "pkrws"
    location = var.deployment_location
}

# Create the virtual network
resource "azurerm_virtual_network" "pkr_build_vnet" {
    name = "pkrws_vnet"
    address_space = [var.vnet_addr_space]
    location = azurerm_resource_group.pkr_rg.location
    resource_group_name = azurerm_resource_group.pkr_rg.name
}

# Create the frontend subnet
resource "azurerm_subnet" "pkr_frontend_subnet" {
    name = "pkr_frontend"
    resource_group_name = azurerm_resource_group.pkr_rg.name
    virtual_network_name = azurerm_virtual_network.pkr_build_vnet.name
    address_prefix = var.frontend_subnet_add_prefix
}

# Create the backend subnet, for deploying only private VMs
resource "azurerm_subnet" "pkr_backend_subnet" {
    name = "pkr_backend"
    resource_group_name = azurerm_resource_group.pkr_rg.name
    virtual_network_name = azurerm_virtual_network.pkr_build_vnet.name
    address_prefix = var.backend_subnet_add_prefix
}

# Create network security groups for the public facing subnet
resource "azurerm_network_security_group" "pkr_frontend_nsg" {
    name = "pkr_frontend_subnet_nsg"
    location = azurerm_resource_group.pkr_rg.location
    resource_group_name = azurerm_resource_group.pkr_rg.name

    security_rule {
        name = "AllowSSH"
        priority = 2048
        direction = "Inbound"
        access = "Allow"
        protocol = "TCP"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = var.my_public_ip
        destination_address_prefix = var.frontend_subnet_add_prefix
    }
}

# Join the NSG with the frontend subnet
resource "azurerm_subnet_network_security_group_association" "join_nsg" {
    subnet_id = azurerm_subnet.pkr_frontend_subnet.id
    network_security_group_id = azurerm_network_security_group.pkr_frontend_nsg.id
}

# Create a public IP resource
resource "azurerm_public_ip" "pkr_builder_vm_ip" {
    name = "pkr_builder_public_ip"
    location = azurerm_resource_group.pkr_rg.location
    resource_group_name = azurerm_resource_group.pkr_rg.name
    allocation_method = "Dynamic"
}

# Create network interface for the VM
resource "azurerm_network_interface" "pkr_builder_nic" {
    name = "pkr_builder_nic"
    location = azurerm_resource_group.pkr_rg.location
    resource_group_name = azurerm_resource_group.pkr_rg.name

    ip_configuration {
        name = "pkr_builder_nic_cfg"
        subnet_id = azurerm_subnet.pkr_frontend_subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.pkr_builder_vm_ip.id
    }
}

# Create storage account to store VM boot diagnostics
resource "random_id" "randomId" {
    keepers = {
        resource_group = azurerm_resource_group.pkr_rg.name
    }
    byte_length = 8
}

resource "azurerm_storage_account" "pkr_rg_storage_acct" {
    name = "diag${random_id.randomId.hex}"
    resource_group_name = azurerm_resource_group.pkr_rg.name
    location = azurerm_resource_group.pkr_rg.location
    account_replication_type = "LRS"
    account_tier = "Standard"
}

# Create a virtual machine in the public subnet
resource "azurerm_virtual_machine" "pkr_build_vm" {
    name = "pkr_builder"
    location = azurerm_resource_group.pkr_rg.location
    resource_group_name = azurerm_resource_group.pkr_rg.name
    network_interface_ids = [
        azurerm_network_interface.pkr_builder_nic.id
    ]
    vm_size = var.vm_size

    boot_diagnostics {
        enabled = true
        storage_uri = azurerm_storage_account.pkr_rg_storage_acct.primary_blob_endpoint
    }

    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = true

    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "18.04-LTS"
        version = "latest"
    }
    storage_os_disk {
        name = "pkr_builder_os_disk"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }
    os_profile {
        computer_name = "pkr-builder"
        admin_username = "ubuntu"
        admin_password = var.admin_password
        custom_data = file(var.custom_data_path)
    }
    os_profile_linux_config {
        disable_password_authentication = false
        ssh_keys {
            path = "/home/ubuntu/.ssh/authorized_keys"
            key_data = file(var.ssh_public_key_path)
        }
    }

    identity {
        type = "SystemAssigned"
    }
}

data "azurerm_role_definition" "builtin_contributor_role" {
    name = "Contributor"
}

data "azurerm_role_definition" "builtin_reader_role" {
    name = "Reader"
}

resource "azurerm_role_assignment" "assign_role_contributor" {
    scope = azurerm_resource_group.pkr_rg.id
    principal_id = azurerm_virtual_machine.pkr_build_vm.identity[0].principal_id
    role_definition_name = "Contributor"
}

resource "azurerm_role_assignment" "assign_role_reader" {
    scope = azurerm_resource_group.pkr_rg.id
    principal_id = azurerm_virtual_machine.pkr_build_vm.identity[0].principal_id
    role_definition_name = "Reader"
}

# Get data
data "azurerm_public_ip" "vm_public_ip" {
  name                = azurerm_public_ip.pkr_builder_vm_ip.name
  resource_group_name = azurerm_virtual_machine.pkr_build_vm.resource_group_name
}

# Deployment outputs
output "vm_public_ip_address" {
    value = data.azurerm_public_ip.vm_public_ip.ip_address
}