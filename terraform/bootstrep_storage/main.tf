provider "azurerm" {
  features {}
  subscription_id = "14737427-c344-422d-8c47-41a65c34bad1"
}

# Resource Group for Terraform State
resource "azurerm_resource_group" "backend_rg" {
  name     = var.backend_rg_name
  location = var.location
}

# Storage Account for Terraform State
resource "azurerm_storage_account" "backend_sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.backend_rg.name
  location                 = azurerm_resource_group.backend_rg.location
  account_tier             = var.tier
  account_replication_type = var.replication
}

# Storage Container for Terraform State
resource "azurerm_storage_container" "backend_container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.backend_sa.name
  container_access_type = var.container_type
}
