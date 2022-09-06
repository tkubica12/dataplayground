// Identity with read secrets rights
resource "azurerm_user_assigned_identity" "datafactory_keyvault_reader" {
  name                = "datafactory-keyvault-reader"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "kv-reader" {
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.datafactory_keyvault_reader.principal_id
}

// Identity with storage writer rights
resource "azurerm_user_assigned_identity" "datafactory_storage_writer" {
  name                = "datafactory-storage-writer"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_role_assignment" "storage-write" {
  scope                = var.datalake_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.datafactory_storage_writer.principal_id
}
