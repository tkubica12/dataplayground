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

  depends_on = [
    azapi_resource.dfcredentials
  ]
}

// SQL
resource "azurerm_data_factory_linked_service_azure_sql_database" "sql" {
  name            = "SQL"
  data_factory_id = azurerm_data_factory.main.id
  key_vault_connection_string {
    linked_service_name = azurerm_data_factory_linked_custom_service.keyvault.name
    secret_name         = "dfsqlconnection"
  }

  depends_on = [
    azurerm_data_factory_linked_custom_service.keyvault
  ]
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

  depends_on = [
    azapi_resource.storage-writer
  ]
}

// Azure Databricks
resource "azurerm_data_factory_linked_custom_service" "databricks" {
  name                 = "Databricks"
  data_factory_id      = azurerm_data_factory.main.id
  type                 = "AzureDatabricks"
  type_properties_json = <<JSON
{
  "domain":"https://${var.databricks_domain_id}",
  "credential": {
    "referenceName": "databricks_df_access",
    "type": "CredentialReference"
  },
  "authentication" : "MSI",
  "workspaceResourceId": "${var.databricks_resource_id}",
  "existingClusterId": "${var.databricks_cluster_id}"
}
JSON
}
