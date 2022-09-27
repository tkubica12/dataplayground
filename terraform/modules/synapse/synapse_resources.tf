// Dataflow
resource "null_resource" "data_flow_ingest_data" {
  provisioner "local-exec" {
    command = "az synapse data-flow create -n IngestData --workspace-name $workspace_name --file @${path.module}/data_flows/ingest_data.json"
    environment = {
      workspace_name = azurerm_synapse_workspace.main.name
    }
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

// Trigger
resource "null_resource" "trigger_every_15_minutes" {
  provisioner "local-exec" {
    command = "az synapse trigger create -n Every15minutes --workspace-name $workspace_name --file @${path.module}/triggers/every_15_minutes.json"
    environment = {
      workspace_name = azurerm_synapse_workspace.main.name
    }
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    null_resource.pipeline_data_pipeline
  ]
}

// Pipeline
resource "null_resource" "pipeline_data_pipeline" {
  provisioner "local-exec" {
    command = "az synapse pipeline create -n DataPipeline --workspace-name $workspace_name --file @${path.module}/pipelines/data_pipeline.json"
    environment = {
      workspace_name = azurerm_synapse_workspace.main.name
    }
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    null_resource.data_flow_ingest_data
  ]
}

// SQL script enagement table
resource "local_file" "engagement_table_file" {
  filename = "${path.module}/sql_scripts/engagement_table.sql"
  content  = <<SQL
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'gold')
BEGIN
    CREATE DATABASE gold;
END

GO

USE gold;

GO

IF NOT EXISTS(SELECT * FROM sys.symmetric_keys WHERE name = 'gold')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'My-Superencryptionpassword@';
END

GO

IF NOT EXISTS(SELECT * FROM sys.database_scoped_credentials WHERE name = 'ManagedIdentity')
BEGIN
    CREATE DATABASE SCOPED CREDENTIAL ManagedIdentity 
    WITH IDENTITY = 'Managed Identity';
END

GO

IF NOT EXISTS(SELECT * FROM sys.external_data_sources WHERE name = 'gold')
BEGIN
    CREATE EXTERNAL DATA SOURCE gold
    WITH ( 
        LOCATION = '${var.datalake_url}gold/',
        CREDENTIAL = ManagedIdentity
        )
END

GO

IF NOT EXISTS(SELECT * FROM sys.external_file_formats WHERE name = 'ParquetFormat')
BEGIN
    CREATE EXTERNAL FILE FORMAT ParquetFormat
    WITH
    (  
        FORMAT_TYPE = PARQUET,
        DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
    )
END

GO

IF NOT EXISTS(SELECT * FROM sys.external_tables WHERE name = 'engagements')
BEGIN
    CREATE EXTERNAL TABLE engagements 
    WITH (
        LOCATION = 'engagements/',
        DATA_SOURCE = gold,
        FILE_FORMAT = ParquetFormat
    )
    AS (
      SELECT users.id, 
            users.user_name, 
            users.city, 
            CASE WHEN vipusers.id >= 0 THEN 1 ELSE 0 END AS is_vip,
            COUNT(pageviews.user_id) AS pageviews,
            COUNT(aggregatedOrders.userId) AS orders,
            SUM(aggregatedOrders.orderValue) AS total_orders_value,
            AVG(aggregatedOrders.orderValue) AS avg_order_value,
            SUM(aggregatedOrders.itemsCount) AS total_items,
            AVG(stars.stars) AS avg_stars
      FROM OPENROWSET(
          BULK '${var.datalake_url}silver/users/',
          FORMAT = 'delta') as users
      LEFT JOIN OPENROWSET(
          BULK '${var.datalake_url}silver/pageviews/',
          FORMAT = 'delta') as pageviews ON users.id = pageviews.user_id
      LEFT JOIN OPENROWSET(
          BULK '${var.datalake_url}silver/stars/',
          FORMAT = 'delta') as stars ON users.id = stars.user_id
      LEFT JOIN OPENROWSET(
          BULK '${var.datalake_url}silver/vipusers/',
          FORMAT = 'delta') as vipusers ON users.id = vipusers.id
      LEFT JOIN (
          SELECT orders.userId, orders.orderValue, orders.orderId, COUNT(items.orderId) AS itemsCount
              FROM OPENROWSET(
              BULK '${var.datalake_url}silver/orders/',
              FORMAT = 'delta') as orders
          LEFT JOIN OPENROWSET(
              BULK '${var.datalake_url}silver/items/',
              FORMAT = 'delta') as items ON orders.orderId = items.orderId
          GROUP BY orders.userId, orders.orderValue, orders.orderId) AS aggregatedOrders ON users.id = aggregatedOrders.userId
      GROUP BY users.id, users.user_name, users.city, vipusers.id
    )
END

GO

-- USE master;
-- DROP DATABASE gold;

SQL
}


resource "null_resource" "sql_script_engagement_table" {
  provisioner "local-exec" {
    command = "az synapse sql-script create -n EngagementTable --workspace-name $workspace_name --file ${path.module}/sql_scripts/engagement_table.sql"
    environment = {
      workspace_name = azurerm_synapse_workspace.main.name
    }
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    local_file.engagement_table_file
  ]
}
