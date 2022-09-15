// Storage Account
resource "azurerm_storage_account" "main" {
  name                     = var.name_prefix
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
}

// Storage containers
resource "azurerm_storage_container" "bronze" {
  name                  = "bronze"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "silver" {
  name                  = "silver"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "gold" {
  name                  = "gold"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "unity" {
  name                  = "unity"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

// Add current account RBAC
data "azurerm_client_config" "storage" {
}

resource "azurerm_role_assignment" "storage-currentuser" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.storage.object_id
}







