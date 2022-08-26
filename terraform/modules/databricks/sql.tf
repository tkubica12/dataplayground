resource "databricks_sql_endpoint" "main" {
  name                      = "sql"
  cluster_size              = "X-Small"
  min_num_clusters          = 1
  max_num_clusters          = 1
  auto_stop_mins            = 10
  spot_instance_policy      = "COST_OPTIMIZED"
  enable_serverless_compute = false

  lifecycle {
    ignore_changes = [num_clusters]
  }
}

resource "databricks_sql_global_config" "msin" {
  security_policy = "DATA_ACCESS_CONTROL"
  data_access_config = {
    "spark.hadoop.fs.azure.account.key.${var.storage_account_name}.dfs.core.windows.net" : "${data.azurerm_storage_account.data_lake.primary_access_key}"
    "spark.hadoop.fs.azure.account.auth.type.${var.storage_account_name}.dfs.core.windows.net" : "SharedKey"
  }
  sql_config_params = {
    "ANSI_MODE" : "true"
  }
}
