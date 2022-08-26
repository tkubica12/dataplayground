// Create Delta Lake
locals {
  createdeltalake = <<CONTENT
-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Create database and Delta tables from Data Lake files

-- COMMAND ----------

USE CATALOG mycatalog;

-- COMMAND ----------

CREATE OR REPLACE TABLE mydb.products
USING delta
SELECT * FROM JSON.`abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/products/`;

GRANT ALL PRIVILEGES ON mydb.products TO `account users`;

-- COMMAND ----------
CREATE OR REPLACE TABLE mydb.vipusers
USING delta
SELECT * FROM JSON.`abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/users/vip.json`;

GRANT ALL PRIVILEGES ON mydb.vipusers TO `account users`;

-- COMMAND ----------

CREATE OR REPLACE TABLE mydb.users
USING delta
SELECT * FROM JSON.`abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/users/users.json`;

GRANT ALL PRIVILEGES ON mydb.users TO `account users`;

-- COMMAND ----------

CREATE OR REPLACE TABLE mydb.orders
USING delta
SELECT * FROM PARQUET.`abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/orders/fromDataFactory.parquet`;

GRANT ALL PRIVILEGES ON mydb.orders TO `account users`;

-- COMMAND ----------

CREATE OR REPLACE TABLE mydb.items
USING delta
SELECT * FROM PARQUET.`abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/items/fromDataFactory.parquet`;

GRANT ALL PRIVILEGES ON mydb.items TO `account users`;

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