// Streaming pipelines
resource "databricks_pipeline" "pageviews" {
  name    = "pageviews"
  storage = "/"
  target = "streaming"

  cluster {
    label       = "default"
    num_workers = 1
  }

  library {
    notebook {
      path = databricks_notebook.delta_live_stream.id
    }
  }

  continuous = false
}

// jobs
resource "databricks_job" "engagement_table" {
  name = "engagement_table"

  existing_cluster_id = databricks_cluster.user_cluster.id

  schedule {
    quartz_cron_expression = "0 */30 * ? * *"
    timezone_id            = "UTC"
  }

  notebook_task {
    notebook_path = databricks_notebook.create_engagement_table.id
  }
}
