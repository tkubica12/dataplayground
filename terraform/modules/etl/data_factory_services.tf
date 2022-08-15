// Key Vault
resource "azurerm_data_factory_linked_custom_service" "keyvault" {
  name                 = "KeyVault"
  data_factory_id      = azurerm_data_factory.main.id
  type                 = "AzureKeyVault"
  type_properties_json = <<JSON
{
  "baseUrl":"${var.keyvault_url}",
  "credential": {
    "referenceName": "kv-reader",
    "type": "CredentialReference"
    }
}
JSON
}

// SQL
resource "azurerm_data_factory_linked_service_azure_sql_database" "sql" {
  name            = "SQL"
  data_factory_id = azurerm_data_factory.main.id
  key_vault_connection_string {
    linked_service_name = azurerm_data_factory_linked_custom_service.keyvault.name
    secret_name         = "dfsqlconnection"
  }
}

// Data Lake storage gen2
resource "azurerm_data_factory_linked_custom_service" "datalake" {
  name                 = "DataLake"
  data_factory_id      = azurerm_data_factory.main.id
  type                 = "AzureBlobFS"
  type_properties_json = <<JSON
{
  "url":"${var.datalake_url}",
  "credential": {
    "referenceName": "storage-writer",
    "type": "CredentialReference"
    }
}
JSON
}
