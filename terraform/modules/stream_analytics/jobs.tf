// Stream Analytics job
resource "azurerm_stream_analytics_job" "main" {
  name                                     = "stream_analytics"
  location                                 = var.location
  resource_group_name                      = var.resource_group_name
  compatibility_level                      = "1.2"
  data_locale                              = "en-GB"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy               = "Adjust"
  output_error_policy                      = "Drop"
  streaming_units                          = 6

  identity {
    type = "SystemAssigned"
  }

  transformation_query = <<QUERY
/* Store RAW data to bronze tier */
SELECT user_id, http_method, uri, client_ip, user_agent, CAST(latency as float) AS latency, EventProcessedUtcTime, PartitionId, EventEnqueuedUtcTime
INTO [raw-pageviews]
FROM [pageviews]

SELECT *
INTO [raw-stars]
FROM [stars]

/* Store VIP only RAW data to bronze tier */
SELECT L.user_id, L.http_method, L.client_ip, L.user_agent, L.latency, L.EventEnqueuedUtcTime, L.uri
INTO [raw-vip-only]
FROM [pageviews] L
JOIN vip R
ON L.user_id = R.id

/* Pageviews and stars correlation */
SELECT L.user_id, L.http_method, L.client_ip, L.user_agent, L.latency, L.EventEnqueuedUtcTime, L.uri, R.stars
INTO [pageviews-stars-correlation]
FROM [pageviews] L
JOIN [stars] R
ON L.user_id = R.user_id AND DATEDIFF(minute,L,R) BETWEEN 0 AND 15  

/* Aggregations */
SELECT COUNT(*) as count, http_method, System.Timestamp() AS WindowEnd
INTO [agg-http-method]
FROM [pageviews]
GROUP BY TumblingWindow(minute, 5), http_method

/* High latency alert */
SELECT *
INTO [alert-high-latency]
FROM [pageviews]
WHERE latency > 2000

/* High latency alert enriched with user lookup */
SELECT L.user_id, L.http_method, L.client_ip, L.user_agent, L.latency, L.EventEnqueuedUtcTime, L.uri, R.name, R.city, R.street_address, R.phone_number, R.birth_number, R.user_name, R.administrative_unit, R.description
INTO [alert-high-latency-enriched]
FROM [pageviews] L
JOIN users R
ON L.user_id = R.id
WHERE L.latency > 2000

/* Detect first event by user over last 60 minutes */
SELECT user_id, client_ip, uri
INTO [first-event-in-user-sequence]
FROM [pageviews]
WHERE ISFIRST(mi, 60) OVER (PARTITION BY user_id) = 1
QUERY
}

// Start
resource "azapi_resource_action" "startcapturepageviews" {
  type                   = "Microsoft.StreamAnalytics/streamingjobs@2020-03-01"
  resource_id            = azurerm_stream_analytics_job.main.id
  action                 = "start"
  response_export_values = ["*"]
  body = jsonencode({
    outputStartMode = "JobStartTime"
  })
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = var.name_prefix
  target_resource_id         = azurerm_stream_analytics_job.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "Execution"
    enabled  = true

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "Authoring"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }
}
