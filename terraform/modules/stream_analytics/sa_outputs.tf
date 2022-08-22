// Storage connection
resource "azurerm_stream_analytics_output_blob" "raw_pageviews" {
  name                      = "raw-pageviews"
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  storage_account_name      = var.datalake_name
  storage_container_name    = "bronze"
  path_pattern              = "pageviews_from_streamanalytics/year={datetime:yyyy}/month={datetime:MM}/day={datetime:dd}"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"
  batch_min_rows            = 20
  batch_max_wait_time       = "00:00:01"
  authentication_mode       = "Msi"

  serialization {
    type = "Parquet"
  }
}

resource "azurerm_stream_analytics_output_blob" "raw_stars" {
  name                      = "raw-stars"
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  storage_account_name      = var.datalake_name
  storage_container_name    = "bronze"
  path_pattern              = "stars_from_streamanalytics/year={datetime:yyyy}/month={datetime:MM}/day={datetime:dd}"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"
  batch_min_rows            = 20
  batch_max_wait_time       = "00:00:01"
  authentication_mode       = "Msi"

  serialization {
    type = "Parquet"
  }
}

resource "azurerm_stream_analytics_output_blob" "raw_vip_only" {
  name                      = "raw-vip-only"
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  storage_account_name      = var.datalake_name
  storage_container_name    = "bronze"
  path_pattern              = "vip_only_from_streamanalytics/year={datetime:yyyy}/month={datetime:MM}/day={datetime:dd}"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"
  batch_min_rows            = 20
  batch_max_wait_time       = "00:00:01"
  authentication_mode       = "Msi"

  serialization {
    type = "Parquet"
  }
}

resource "azurerm_stream_analytics_output_blob" "pageviews_stars_correlation" {
  name                      = "pageviews-stars-correlation"
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  storage_account_name      = var.datalake_name
  storage_container_name    = "silver"
  path_pattern              = "pageviews_stars_correlation_from_streamanalytics/year={datetime:yyyy}/month={datetime:MM}/day={datetime:dd}"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"
  batch_min_rows            = 20
  batch_max_wait_time       = "00:00:01"
  authentication_mode       = "Msi"

  serialization {
    type = "Parquet"
  }
}

resource "azurerm_stream_analytics_output_blob" "agg_http_method" {
  name                      = "agg-http-method"
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  storage_account_name      = var.datalake_name
  storage_container_name    = "silver"
  path_pattern              = "pageviews_by_http_method/year={datetime:yyyy}/month={datetime:MM}/day={datetime:dd}"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"
  batch_min_rows            = 20
  batch_max_wait_time       = "00:00:01"
  authentication_mode       = "Msi"

  serialization {
    type     = "Json"
    encoding = "UTF8"
    format   = "LineSeparated"
  }
}

resource "azurerm_stream_analytics_output_blob" "alert_high_latency" {
  name                      = "alert-high-latency"
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  storage_account_name      = var.datalake_name
  storage_container_name    = "silver"
  path_pattern              = "pageviews_high_latency/year={datetime:yyyy}/month={datetime:MM}/day={datetime:dd}"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"
  batch_min_rows            = 20
  batch_max_wait_time       = "00:00:01"
  authentication_mode       = "Msi"

  serialization {
    type     = "Json"
    encoding = "UTF8"
    format   = "LineSeparated"
  }
}

resource "azurerm_stream_analytics_output_blob" "alert_high_latency_enriched" {
  name                      = "alert-high-latency-enriched"
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  storage_account_name      = var.datalake_name
  storage_container_name    = "silver"
  path_pattern              = "pageviews_high_latency_enriched/year={datetime:yyyy}/month={datetime:MM}/day={datetime:dd}"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"
  batch_min_rows            = 20
  batch_max_wait_time       = "00:00:01"
  authentication_mode       = "Msi"

  serialization {
    type     = "Json"
    encoding = "UTF8"
    format   = "LineSeparated"
  }
}

