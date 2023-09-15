variable "deployment_location" {
    type = string
    default = "eastus"
}

variable "vnet_addr_space" {
    type = string
    default = "10.0.0.0/24"
}

variable "frontend_subnet_add_prefix" {
    type = string
    default = "10.0.0.0/25"
}

variable "backend_subnet_add_prefix" {
    type = string
    default = "10.0.0.128/25"
}

variable "my_public_ip" {
    type = string
    description = "Provide the public IP of the machine/network from which incoming SSH connections must be allowed"
}

variable "ssh_public_key_path" {
    type = string
    description = "Full path to the VM SSH access public key"
}

variable "custom_data_path" {
    type = string
    default = "./custom_data/init.yml"
}

variable "admin_password" {
    type = string
    description = "Provide a strong admin password"
}

variable "vm_size" {
    type = string
    description = "Default VM size"
    default = "Standard_D2_v2"
}