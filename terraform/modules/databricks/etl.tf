// Jobs
resource "databricks_job" "data_lake_loader" {
  name = "data_lake_loader"

  existing_cluster_id = databricks_cluster.single_user_cluster.id

  schedule {
    quartz_cron_expression = "0 */50 * ? * *"
    timezone_id            = "UTC"
  }

  notebook_task {
    notebook_path = databricks_notebook.data_lake_loader.id
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
    notebook_path = databricks_notebook.sql_loader.id
  }
}

// BRONZE-to-SILVER: Users, VIP users, products
locals {
  data_lake_loader = <<CONTENT
# Databricks notebook source
# MAGIC %md
# MAGIC # Users

# COMMAND ----------

data_path = "abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/users/"
checkpoint_path = "abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/_checkpoint/users"

(spark.readStream
  .format("cloudFiles")
  .option("cloudFiles.format", "json")
  .option("cloudFiles.schemaLocation", checkpoint_path)
  .load(data_path)
  .writeStream
  .option("checkpointLocation", checkpoint_path)
  .trigger(availableNow=True)
  .toTable("mycatalog.mydb.users"))

# COMMAND ----------

# MAGIC %md
# MAGIC # VIP Users

# COMMAND ----------

data_path = "abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/vipusers/"
checkpoint_path = "abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/_checkpoint/vipusers"

(spark.readStream
  .format("cloudFiles")
  .option("cloudFiles.format", "json")
  .option("cloudFiles.schemaLocation", checkpoint_path)
  .load(data_path)
  .writeStream
  .option("checkpointLocation", checkpoint_path)
  .trigger(availableNow=True)
  .toTable("mycatalog.mydb.vipusers"))

# COMMAND ----------

# MAGIC %md
# MAGIC # Products

# COMMAND ----------

data_path = "abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/products/"
checkpoint_path = "abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/_checkpoint/products"

(spark.readStream
  .format("cloudFiles")
  .option("cloudFiles.format", "json")
  .option("cloudFiles.schemaLocation", checkpoint_path)
  .load(data_path)
  .writeStream
  .option("checkpointLocation", checkpoint_path)
  .trigger(availableNow=True)
  .toTable("mycatalog.mydb.products"))
CONTENT
}

resource "databricks_notebook" "data_lake_loader" {
  content_base64 = base64encode(local.data_lake_loader)
  language       = "PYTHON"
  path           = "/Shared/data_lake_loader"
}

// BRONZE-to-SILVER: SQL loader for orders and items
locals {
  sql_loader = <<CONTENT
-- Databricks notebook source
CREATE TABLE IF NOT EXISTS jdbc_orders
USING org.apache.spark.sql.jdbc
OPTIONS (
  url "jdbc:sqlserver://lsafbfuvyjbm.database.windows.net:1433;database=orders",
  database "orders",
  dbtable "orders",
  user "tomas",
  password "zTmoZoCU?o5QtnhG"
)

-- COMMAND ----------

CREATE OR REPLACE TABLE mycatalog.mydb.orders
AS SELECT * FROM jdbc_orders

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS jdbc_items
USING org.apache.spark.sql.jdbc
OPTIONS (
  url "jdbc:sqlserver://lsafbfuvyjbm.database.windows.net:1433;database=orders",
  database "orders",
  dbtable "items",
  user "tomas",
  password "zTmoZoCU?o5QtnhG"
)

-- COMMAND ----------

CREATE OR REPLACE TABLE mycatalog.mydb.items
AS SELECT * FROM jdbc_items

-- COMMAND ----------

CONTENT
}

resource "databricks_notebook" "sql_loader" {
  content_base64 = base64encode(local.sql_loader)
  language       = "SQL"
  path           = "/Shared/sql_loader"
}