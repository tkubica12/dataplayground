// Stream Analytics job
resource "azurerm_stream_analytics_job" "main" {
  name                                     = "sa-capture-pageviews"
  location                                 = var.location
  resource_group_name                      = var.resource_group_name
  compatibility_level                      = "1.2"
  data_locale                              = "en-GB"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy               = "Adjust"
  output_error_policy                      = "Drop"
  streaming_units                          = 1

  identity {
    type = "SystemAssigned"
  }

  transformation_query = <<QUERY
    SELECT *
    INTO [blob]
    FROM [pageviews]
QUERY
}

// Event Hub connection
resource "azurerm_eventhub_consumer_group" "streamanalytics-capture" {
  name                = "streamanalytics-capture"
  namespace_name      = var.eventhub_namespace_name
  eventhub_name       = var.eventhub_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_eventhub_namespace_authorization_rule" "streamanalytics-capture" {
  name                = "streamanalytics-capture"
  namespace_name      = var.eventhub_namespace_name
  resource_group_name = var.resource_group_name

  listen = true
  send   = false
  manage = false
}

resource "azurerm_stream_analytics_stream_input_eventhub" "main" {
  name                         = "pageviews"
  stream_analytics_job_name    = azurerm_stream_analytics_job.main.name
  resource_group_name          = var.resource_group_name
  eventhub_consumer_group_name = azurerm_eventhub_consumer_group.streamanalytics-capture.name
  eventhub_name                = var.eventhub_name
  servicebus_namespace         = var.eventhub_namespace_name
  shared_access_policy_key     = azurerm_eventhub_namespace_authorization_rule.streamanalytics-capture.primary_key
  shared_access_policy_name    = azurerm_eventhub_namespace_authorization_rule.streamanalytics-capture.name

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

// Storage connection
resource "azurerm_stream_analytics_output_blob" "blob" {
  name                      = "blob"
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  storage_account_name      = var.datalake_name
  storage_container_name    = "bronze"
  path_pattern              = "pageviews_from_streamanalytics/year={datetime:yyyy}/month={datetime:MM}/day={datetime:dd}"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"
  batch_min_rows            = 60
  batch_max_wait_time       = "00:00:03"
  authentication_mode       = "Msi"

  serialization {
    type = "Parquet"
  }
}

resource "random_uuid" "storage-streamanalytics" {
}

resource "azurerm_role_assignment" "storage-streamanalytics" {
  name                 = random_uuid.storage-streamanalytics.result
  scope                = var.datalake_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_stream_analytics_job.main.identity[0].principal_id
}
