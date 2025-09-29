variable "backend_rg_name" {
  type        = string
  description = "Resource Group for backend storage"
  default = "terraform-backend-rg"
}

variable "location" {
  type        = string
  description = "Azure region"
  default = "East US"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"
  default = "Hylastixsafestore"
}

variable "tier" {
  type        = string
  default     = "Standard"
}

variable "replication" {
  type        = string
  default     = "LRS"
}

variable "container_name" {
  type        = string
  description = "Storage container name for state file"
  default = "Hylastixsafestore280925"
}

variable "container_type" {
  type        = string
  description = "Container type for state file"
  default = "private"
}
