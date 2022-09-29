resource "databricks_sql_query" "query_engagements" {
  data_source_id = databricks_sql_endpoint.main.data_source_id
  name           = "engagements"
  run_as_role    = "viewer"
  query          = <<QUERY
SELECT * FROM mycatalog.mydb.engagements
QUERY
}

# resource "databricks_permissions" "query_engagements" {
#   sql_query_id = databricks_sql_query.query_engagements.id

#   access_control {
#     group_name       = "account users"
#     permission_level = "CAN_RUN"
#   }
# }

resource "databricks_sql_dashboard" "dashboard_engagements" {
  name = "My engagements report"
}

# resource "databricks_permissions" "dashboard_engagements" {
#   sql_dashboard_id = databricks_sql_dashboard.dashboard_engagements.id

#   access_control {
#     group_name       = "account users"
#     permission_level = "CAN_RUN"
#   }
# }

