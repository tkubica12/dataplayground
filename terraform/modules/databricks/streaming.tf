// Pipeline
resource "databricks_pipeline" "streaming" {
  name    = "streaming"
  storage = "/"
  target  = "streaming"
  edition = "Pro"

  cluster {
    label       = "default"
    num_workers = 1
  }

  library {
    notebook {
      path = databricks_notebook.delta_live_stream_ingestion.id
    }
  }

  library {
    notebook {
      path = databricks_notebook.delta_live_stream_parsing.id
    }
  }

  library {
    notebook {
      path = databricks_notebook.delta_live_stream_processing.id
    }
  }

  continuous = true
}

// Ingestion
locals {
  delta_live_stream_ingestion = <<CONTENT
import dlt
from pyspark.sql.functions import *
from pyspark.sql.types import *

@dlt.table
def stream_pageviews():
    connection = 'kafkashaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="Endpoint=sb://${var.eventhub_namespace_name}.servicebus.windows.net/;SharedAccessKeyName=pageviewsReceiver;SharedAccessKey=${azurerm_eventhub_authorization_rule.pageviewsReceiver.primary_key}";'

    kafka_options = {
     "kafka.bootstrap.servers": "${var.eventhub_namespace_name}.servicebus.windows.net:9093",
     "kafka.sasl.mechanism": "PLAIN",
     "kafka.security.protocol": "SASL_SSL",
     "kafka.request.timeout.ms": "60000",
     "kafka.session.timeout.ms": "30000",
     "startingOffsets": "earliest",
     "kafka.sasl.jaas.config": connection,
     "subscribe": "pageviews",
      }
    return spark.readStream.format("kafka").options(**kafka_options).load()

@dlt.table
def stream_stars():
    connection = 'kafkashaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="Endpoint=sb://${var.eventhub_namespace_name}.servicebus.windows.net/;SharedAccessKeyName=starsReceiver;SharedAccessKey=${azurerm_eventhub_authorization_rule.starsReceiver.primary_key}";'

    kafka_options = {
     "kafka.bootstrap.servers": "${var.eventhub_namespace_name}.servicebus.windows.net:9093",
     "kafka.sasl.mechanism": "PLAIN",
     "kafka.security.protocol": "SASL_SSL",
     "kafka.request.timeout.ms": "60000",
     "kafka.session.timeout.ms": "30000",
     "startingOffsets": "earliest",
     "kafka.sasl.jaas.config": connection,
     "subscribe": "stars",
      }
    return spark.readStream.format("kafka").options(**kafka_options).load()

CONTENT
}

resource "databricks_notebook" "delta_live_stream_ingestion" {
  content_base64 = base64encode(local.delta_live_stream_ingestion)
  language       = "PYTHON"
  path           = "/DemoStreaming/delta_live_stream_ingestion"
}

// Parsing
locals {
  delta_live_stream_parsing = <<CONTENT
-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Parse pageviews

-- COMMAND ----------

CREATE OR REFRESH STREAMING LIVE TABLE parsed_pageviews
AS SELECT timestamp,
  get_json_object(CAST(value AS string), '$.user_id') AS user_id,
  get_json_object(CAST(value AS string), '$.http_method') AS http_method,
  get_json_object(CAST(value AS string), '$.uri') AS uri,
  get_json_object(CAST(value AS string), '$.client_ip') AS client_ip,
  get_json_object(CAST(value AS string), '$.user_agent') AS user_agent, 
  get_json_object(CAST(value AS string), '$.latency') AS latency 
FROM STREAM(live.stream_pageviews)

-- COMMAND ----------

CREATE OR REFRESH STREAMING LIVE TABLE parsed_stars
AS SELECT timestamp,
  get_json_object(CAST(value AS string), '$.user_id') AS user_id,
  get_json_object(CAST(value AS string), '$.stars') AS stars
FROM STREAM(live.stream_stars)

-- COMMAND ----------

-- COMMAND ----------

CONTENT
}

resource "databricks_notebook" "delta_live_stream_parsing" {
  content_base64 = base64encode(local.delta_live_stream_parsing)
  language       = "SQL"
  path           = "/DemoStreaming/delta_live_stream_parsing"
}


// Processing
// NOTE: waiting for Unity Catalog support to complete


# -- COMMAND ----------

# CREATE OR REFRESH STREAMING LIVE TABLE high_latency_enriched
# AS SELECT *
# FROM STREAM(live.parsed_pageviews)
# LEFT JOIN mycatalog.mydb.users ON parsed_pageviews.user_id = mycatalog.mydb.users.id
# WHERE parsed_pageviews.latency > 2000

# -- COMMAND ----------

# CREATE OR REFRESH STREAMING LIVE TABLE vip_only_pageviews
# AS SELECT *
# FROM STREAM(live.parsed_pageviews)
# INNER JOIN mycatalog.mydb.vipusers ON parsed_pageviews.user_id = mycatalog.mydb.vipusers.id

locals {
  delta_live_stream_processing = <<CONTENT
-- Databricks notebook source
-- MAGIC %md
-- MAGIC # High latency alert

-- COMMAND ----------

CREATE OR REFRESH STREAMING LIVE TABLE high_latency
AS SELECT *
FROM STREAM(live.parsed_pageviews)
WHERE latency > 4000

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Pageviews with stars correlation

-- COMMAND ----------

CREATE OR REFRESH STREAMING LIVE TABLE pageviews_stars_correlation
AS SELECT live.parsed_pageviews.user_id,
          live.parsed_pageviews.http_method,
          live.parsed_pageviews.uri,
          live.parsed_pageviews.client_ip,
          live.parsed_pageviews.user_agent,
          live.parsed_pageviews.latency,
          live.parsed_stars.stars
FROM STREAM(live.parsed_pageviews)
JOIN STREAM(live.parsed_stars)
  ON live.parsed_pageviews.user_id = live.parsed_stars.user_id
  AND DATEDIFF(MINUTE, live.parsed_pageviews.timestamp,live.parsed_stars.timestamp) BETWEEN 0 AND 15  

-- COMMAND ----------

CONTENT
}

resource "databricks_notebook" "delta_live_stream_processing" {
  content_base64 = base64encode(local.delta_live_stream_processing)
  language       = "SQL"
  path           = "/DemoStreaming/delta_live_stream_processing"
}

