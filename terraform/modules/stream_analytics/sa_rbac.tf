resource "random_uuid" "stream_analytics" {
}

resource "azurerm_role_assignment" "stream_analytics" {
  name                 = random_uuid.stream_analytics.result
  scope                = var.datalake_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_stream_analytics_job.main.identity[0].principal_id
}

resource "azurerm_eventhub_consumer_group" "eventhub" {
  name                = "stream_analytics"
  namespace_name      = var.eventhub_namespace_name
  eventhub_name       = var.eventhub_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_eventhub_namespace_authorization_rule" "eventhub" {
  name                = "stream_analytics"
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.resource_group_name

  listen = true
  send   = false
  manage = false
}