resource "databricks_pipeline" "pageviews" {
  name    = "pageviews"
  storage = "/mycatalog"
  target = "mydb"

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