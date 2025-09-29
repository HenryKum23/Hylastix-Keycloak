variable "vm_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "adminvm"
}

variable "location" {
  description = "Location of the resource group"
  type        = string
  default     = "northeurope"
}

variable "vnet" {
  description = "CIDR blocks for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"] # Example CIDR block for the VNet
}

variable "subnet" {
  description = "CIDR blocks for the subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"] # Example CIDR block for the subnet
}

variable "vm_size" {
  description = "value of the VM size"
  type        = string
  default = "Standard_D2as_v5"
}

variable "disk" {
  description = "OS disk config"
  type        = string
  default = "Premium_LRS"
}

variable "comp_name" {
  description = "Computer name in vm"
  type        = string
  default = "Henry_Keycloak"
}

#Use a single object variable (clean and DRY)
variable "resource_names" {
  type = object({
    rg     = string
    vnet   = string
    subnet = string
    pip    = string
    nic    = string
    nsg    = string
    vm     = string
  })

  default = {
    rg     = "keycloak-rg"
    vnet   = "keycloak-vnet"
    subnet = "keycloak-subnet"
    pip    = "keycloak-pip"
    nic    = "keycloak-nic"
    nsg    = "keycloak-nsg"
    vm     = "keycloak-vm"
  }
}

variable "backend_rg_name" {
  type        = string
  description = "Resource Group for backend storage"
  default = "terraform-backend-rg"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"
  default = "hylastixsafestore"
}

variable "container_name" {
  type        = string
  description = "Storage container name for state file"
  default = "hylastixsafe2809"
}