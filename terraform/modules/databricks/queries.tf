resource "databricks_sql_query" "alert_high_latency" {
  data_source_id = databricks_sql_endpoint.main.data_source_id
  name           = "alert_high_latency"
  run_as_role    = "viewer"
  query          = <<QUERY
SELECT EventEnqueuedUtcTime AS Time, client_ip, http_method, latency, uri, user_agent, user_id
FROM JSON.`abfss://silver@${var.storage_account_name}.dfs.core.windows.net/streamanalytics/pageviews_high_latency`
ORDER BY EventEnqueuedUtcTime DESC
QUERY

  schedule {
    continuous {
      interval_seconds = 60
    }
  }
}

resource "databricks_sql_query" "alert_high_latency_enriched" {
  data_source_id = databricks_sql_endpoint.main.data_source_id
  name           = "alert_high_latency_enriched"
  run_as_role    = "viewer"
  query          = <<QUERY
SELECT EventEnqueuedUtcTime AS Time, client_ip, http_method, latency, user_agent, user_id, name, street_address, phone_number
FROM JSON.`abfss://silver@${var.storage_account_name}.dfs.core.windows.net/streamanalytics/pageviews_high_latency_enriched`
ORDER BY EventEnqueuedUtcTime DESC
QUERY

  schedule {
    continuous {
      interval_seconds = 60
    }
  }
}

resource "databricks_sql_query" "pageviews_by_http_method" {
  data_source_id = databricks_sql_endpoint.main.data_source_id
  name           = "pageviews_by_http_method"
  run_as_role    = "viewer"
  query          = <<QUERY
SELECT *
FROM JSON.`abfss://silver@${var.storage_account_name}.dfs.core.windows.net/streamanalytics/pageviews_by_http_method`
ORDER BY EventEnqueuedUtcTime DESC
QUERY

  schedule {
    continuous {
      interval_seconds = 60
    }
  }
}

resource "databricks_sql_query" "pageviews_stars_correlation_from_streamanalytics" {
  data_source_id = databricks_sql_endpoint.main.data_source_id
  name           = "pageviews_stars_correlation_from_streamanalytics"
  run_as_role    = "viewer"
  query          = <<QUERY
SELECT *
FROM JSON.`abfss://silver@${var.storage_account_name}.dfs.core.windows.net/streamanalytics/pageviews_stars_correlation`
ORDER BY EventEnqueuedUtcTime DESC
QUERY

  schedule {
    continuous {
      interval_seconds = 60
    }
  }
}

# resource "databricks_permissions" "alert_high_latency" {
#   sql_query_id = databricks_sql_query.alert_high_latency.id

#   access_control {
#     group_name       = data.databricks_group.users.display_name
#     permission_level = "CAN_RUN"
#   }

#   // You can only specify "CAN_EDIT" permissions if the query `run_as_role` equals `viewer`.
#   access_control {
#     group_name       = data.databricks_group.team.display_name
#     permission_level = "CAN_EDIT"
#   }
# }
