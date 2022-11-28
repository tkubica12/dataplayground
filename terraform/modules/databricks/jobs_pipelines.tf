// Jobs
resource "databricks_job" "data_lake_loader" {
  name = "data_lake_loader"

  existing_cluster_id = databricks_cluster.single_user_cluster.id

  schedule {
    quartz_cron_expression = "0 */50 * ? * *"
    timezone_id            = "UTC"
  }

  notebook_task {
    notebook_path = "${databricks_repo.main.path}/databricks/data_lake_loader"
  }
}

resource "databricks_job" "sql_loader" {
  name = "sql_loader"

  existing_cluster_id = databricks_cluster.single_user_cluster.id

  schedule {
    quartz_cron_expression = "0 */50 * ? * *"
    timezone_id            = "UTC"
  }

  notebook_task {
    notebook_path = "${databricks_repo.main.path}/databricks/sql_loader"
  }
}

resource "databricks_job" "engagement_table" {
  name = "engagement_table"

  existing_cluster_id = databricks_cluster.single_user_cluster.id

  schedule {
    quartz_cron_expression = "0 */50 * ? * *"
    timezone_id            = "UTC"
  }

  notebook_task {
    notebook_path = "${databricks_repo.main.path}/databricks/create_engagement_table"
  }
}
