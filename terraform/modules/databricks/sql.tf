resource "databricks_sql_endpoint" "main" {
  name                      = "sql"
  cluster_size              = "2X-Small"
  min_num_clusters          = 1
  max_num_clusters          = 1
  auto_stop_mins            = 10
  spot_instance_policy      = "COST_OPTIMIZED"
  enable_serverless_compute = true
  warehouse_type            = "PRO"

  lifecycle {
    ignore_changes = [num_clusters]
  }
}

resource "databricks_sql_global_config" "msin" {
  security_policy = "DATA_ACCESS_CONTROL"
  data_access_config = {

  }
  sql_config_params = {
    "ANSI_MODE" : "true"
  }
}
