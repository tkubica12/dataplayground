// Create Delta Lake
locals {
  createdeltalake = <<CONTENT
-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Create database and Delta tables from Data Lake files

-- COMMAND ----------

USE CATALOG mycatalog;

-- COMMAND ----------

COPY INTO mydb.products
FROM 'abfss://bronze@gwecyjbnxwgk.dfs.core.windows.net/products/'
FILEFORMAT = JSON;

-- COMMAND ----------

COPY INTO mydb.vipusers
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/users/vip.json'
FILEFORMAT = JSON;

-- COMMAND ----------

COPY INTO mydb.users
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/users/users.json'
FILEFORMAT = JSON;

-- COMMAND ----------

COPY INTO mydb.orders
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/orders/fromDataFactory.parquet'
FILEFORMAT = PARQUET;

-- COMMAND ----------

COPY INTO mydb.items
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/items/fromDataFactory.parquet'
FILEFORMAT = PARQUET;

-- COMMAND ----------

COPY INTO mydb.pageviews
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/streamanalytics/pageviews/'
FILEFORMAT = PARQUET;

-- COMMAND ----------

COPY INTO mydb.stars
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/streamanalytics/stars/'
FILEFORMAT = PARQUET;

-- COMMAND ----------
CONTENT
}

resource "databricks_notebook" "createdeltalake" {
  content_base64 = base64encode(local.createdeltalake)
  language = "SQL"
  path   = "/Shared/CreateDeltaLake"
}


// Example queries
locals {
  examplequeries = <<CONTENT
-- Databricks notebook source

-- MAGIC %md 
-- MAGIC # Test few queries

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Check tables

-- COMMAND ----------

USE CATALOG mycatalog;

-- COMMAND ----------

SELECT * FROM mydb.orders LIMIT 10

-- COMMAND ----------

SELECT * FROM mydb.items LIMIT 10

-- COMMAND ----------

SELECT * FROM mydb.users LIMIT 10

-- COMMAND ----------

SELECT * FROM mydb.products LIMIT 10

-- COMMAND ----------

SELECT * FROM mydb.pageviews LIMIT 10

-- COMMAND ----------

SELECT * FROM mydb.stars LIMIT 10

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Summarize orders by customer

-- COMMAND ----------

SELECT count(*) as numberOfOrders, sum(orderValue) as sumValue 
FROM mydb.orders 
GROUP BY userId
ORDER BY numberOfOrders desc

-- COMMAND ----------

CONTENT
}

resource "databricks_notebook" "examplequeries" {
  content_base64 = base64encode(local.examplequeries)
  language = "SQL"
  path   = "/Shared/ExampleQueries"
}