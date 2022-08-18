// Create Delta Lake
locals {
  createdeltalake = <<CONTENT
-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Create database and Delta tables from Data Lake files

-- COMMAND ----------

CREATE DATABASE IF NOT EXISTS mojedb;

-- COMMAND ----------

CREATE OR REPLACE TABLE mojedb.items
USING delta
LOCATION 'abfss://silver@${var.storage_account_name}.dfs.core.windows.net/itemsDeltaTable'
SELECT * FROM PARQUET.`abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/items/fromDataFactory.parquet`;

-- COMMAND ----------

CREATE OR REPLACE TABLE mojedb.orders
USING delta
LOCATION 'abfss://silver@${var.storage_account_name}.dfs.core.windows.net/ordersDeltaTable'
SELECT * FROM PARQUET.`abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/orders/fromDataFactory.parquet`;

-- COMMAND ----------

CREATE OR REPLACE TABLE mojedb.users
USING delta
LOCATION 'abfss://silver@${var.storage_account_name}.dfs.core.windows.net/usersDeltaTable'
SELECT * FROM JSON.`abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/users/users.json`;

-- COMMAND ----------

CREATE OR REPLACE TABLE mojedb.products
USING delta
LOCATION 'abfss://silver@${var.storage_account_name}.dfs.core.windows.net/productsDeltaTable'
SELECT * FROM JSON.`abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/products/`;

-- COMMAND ----------

CREATE OR REPLACE TABLE mojedb.pageviews
USING delta
LOCATION 'abfss://silver@${var.storage_account_name}.dfs.core.windows.net/pageviewsDeltaTable'
SELECT * FROM AVRO.`abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/pageviews_from_capture/**/**/**/**/**/**/**/**`;

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

SELECT * FROM mojedb.orders LIMIT 10

-- COMMAND ----------

SELECT * FROM mojedb.items LIMIT 10

-- COMMAND ----------

SELECT * FROM mojedb.users LIMIT 10

-- COMMAND ----------

SELECT * FROM mojedb.products LIMIT 10

-- COMMAND ----------

SELECT * FROM mojedb.pageviews LIMIT 10

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Summarize orders by customer

-- COMMAND ----------

SELECT count(*) as numberOfOrders, sum(orderValue) as sumValue 
FROM mojedb.orders 
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