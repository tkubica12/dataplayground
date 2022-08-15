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


# Server=tcp:myserver.database.windows.net,1433;Database=@{linkedService().DBName};User ID=user;Password=fake;Trusted_Connection=False;Encrypt=True;Connection Timeout=30
