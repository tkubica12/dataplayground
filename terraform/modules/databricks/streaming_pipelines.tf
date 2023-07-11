resource "databricks_pipeline" "streaming" {
  name    = "streaming"
  catalog = databricks_catalog.main.name
  target  = "streaming"
  edition = "PRO"
  channel = "preview"     # As of July 2023 preview needed to support Unity Catalog in DLT

  cluster {
    label       = "default"
    num_workers = 0
    spark_conf = {
      "spark.master" = "local[*]"
    }
  }

  library {
    notebook {
      path = "${databricks_repo.main.path}/databricks/DemoStreaming/delta_live_stream_ingestion"
    }
  }

  library {
    notebook {
      path = "${databricks_repo.main.path}/databricks/DemoStreaming/delta_live_stream_parsing"
    }
  }

  library {
    notebook {
      path = "${databricks_repo.main.path}/databricks/DemoStreaming/delta_live_stream_processing"
    }
  }

  library {
    notebook {
      path = "${databricks_repo.main.path}/databricks/DemoStreaming/delta_live_engagements"
    }
  }

  continuous = true
}
