resource "azurerm_role_assignment" "main" {
  scope                = var.datalake_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.main.identity.0.principal_id
}

resource "azurerm_role_assignment" "keyvault" {
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_synapse_workspace.main.identity.0.principal_id
}