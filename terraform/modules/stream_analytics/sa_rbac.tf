// Managed identity RBAC to storage
resource "random_uuid" "stream_analytics" {
}

resource "azurerm_role_assignment" "stream_analytics" {
  name                 = random_uuid.stream_analytics.result
  scope                = var.datalake_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_stream_analytics_job.main.identity[0].principal_id
}

// Managed identity RBAC to Event Hubs
resource "random_uuid" "event_hub_pageviews" {
}

resource "azurerm_role_assignment" "event_hub_pageviews" {
  name                 = random_uuid.event_hub_pageviews.result
  scope                = var.eventhub_id_pageviews
  role_definition_name = "Azure Event Hubs Data Owner"
  principal_id         = azurerm_stream_analytics_job.main.identity[0].principal_id
}

resource "random_uuid" "event_hub_stars" {
}

resource "azurerm_role_assignment" "event_hub_stars" {
  name                 = random_uuid.event_hub_stars.result
  scope                = var.eventhub_id_stars
  role_definition_name = "Azure Event Hubs Data Owner"
  principal_id         = azurerm_stream_analytics_job.main.identity[0].principal_id
}

