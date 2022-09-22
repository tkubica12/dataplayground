resource "azurerm_synapse_linked_service" "datalake" {
  name                 = "datalake"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  type                 = "AzureBlobFS"
  type_properties_json = <<JSON
{
  "url": ${var.datakale_url}
}
JSON

  depends_on = [
    azurerm_synapse_firewall_rule.all,
  ]
}