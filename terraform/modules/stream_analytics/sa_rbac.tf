resource "random_uuid" "stream_analytics" {
}

resource "azurerm_role_assignment" "stream_analytics" {
  name                 = random_uuid.stream_analytics.result
  scope                = var.datalake_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_stream_analytics_job.main.identity[0].principal_id
}

resource "azurerm_eventhub_consumer_group" "pageviews" {
  name                = "pageviews"
  namespace_name      = var.eventhub_namespace_name
  eventhub_name       = var.eventhub_name_pageviews
  resource_group_name = var.resource_group_name
}

resource "azurerm_eventhub_authorization_rule" "pageviews" {
  name                = "pageviews"
  namespace_name      = var.eventhub_namespace_name
  eventhub_name       = var.eventhub_name_pageviews
  resource_group_name = var.resource_group_name

  listen = true
  send   = false
  manage = false
}

resource "azurerm_eventhub_consumer_group" "stars" {
  name                = "stars"
  namespace_name      = var.eventhub_namespace_name
  eventhub_name       = var.eventhub_name_stars
  resource_group_name = var.resource_group_name
}

resource "azurerm_eventhub_authorization_rule" "stars" {
  name                = "stars"
  namespace_name      = var.eventhub_namespace_name
  eventhub_name       = var.eventhub_name_stars
  resource_group_name = var.resource_group_name

  listen = true
  send   = false
  manage = false
}
