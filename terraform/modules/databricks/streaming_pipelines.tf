resource "databricks_pipeline" "streaming" {
  name    = "streaming"
  storage = "/"
  target  = "streaming"
  edition = "PRO"

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

  continuous = true
}
