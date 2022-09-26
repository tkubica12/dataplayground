// Data lake
resource "azurerm_synapse_linked_service" "datalake" {
  name                 = "datalake"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  type                 = "AzureBlobFS"
  type_properties_json = <<JSON
{
  "url": "${var.datalake_url}"
}
JSON

  depends_on = [
    azurerm_synapse_firewall_rule.all,
  ]
}

// Key Vault
resource "azurerm_synapse_linked_service" "keyvault" {
  name                 = "KeyVault"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  type                 = "AzureKeyVault"
  type_properties_json = <<JSON
{
  "baseUrl":"${var.keyvault_url}"
}
JSON

  depends_on = [
    azurerm_synapse_firewall_rule.all,
  ]
}

// SQL
resource "azurerm_synapse_linked_service" "sql" {
  name                 = "SQL"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  type                 = "AzureSqlDatabase"
  type_properties_json = <<JSON
{
  "connectionString": {
      "type": "AzureKeyVaultSecret",
      "store": {
          "referenceName": "KeyVault",
          "type": "LinkedServiceReference"
      },
      "secretName": "dfsqlconnection"
  }
}
JSON

  depends_on = [
    azurerm_synapse_firewall_rule.all,
  ]
}
