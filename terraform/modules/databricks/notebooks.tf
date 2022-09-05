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
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/products/'  WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = JSON;

-- COMMAND ----------

COPY INTO mydb.vipusers
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/users/vip.json'  WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = JSON;

-- COMMAND ----------

COPY INTO mydb.users
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/users/users.json'  WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = JSON;

-- COMMAND ----------

COPY INTO mydb.orders
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/orders/fromDataFactory.parquet'  WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = PARQUET;

-- COMMAND ----------

COPY INTO mydb.items
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/items/fromDataFactory.parquet'  WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = PARQUET;

-- COMMAND ----------

COPY INTO mydb.pageviews
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/streamanalytics/pageviews/'  WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = PARQUET;

-- COMMAND ----------

COPY INTO mydb.stars
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/streamanalytics/stars/'  WITH (
  CREDENTIAL `mi_credential`
)
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


// User engagement table
locals {
  create_engagement_table = <<CONTENT
-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Precalculate User Engagement table
-- COMMAND ----------

USE CATALOG mycatalog;

-- COMMAND ----------

SELECT users.id, 
  users.user_name, 
  users.city, 
  COUNT(pageviews.user_id) AS pageviews, 
  COUNT(aggregatedOrders.userId) AS orders,
  SUM(aggregatedOrders.orderValue) AS total_orders_value,
  AVG(aggregatedOrders.orderValue) AS avg_order_value,
  SUM(aggregatedOrders.itemsCount) AS total_items,
  AVG(stars.stars) AS avg_stars,
  iff(isnull(vipusers.id), false, true) AS is_vip
FROM mydb.users
LEFT JOIN mydb.pageviews ON users.id = pageviews.user_id
LEFT JOIN (
  SELECT orders.userId, orders.orderValue, orders.orderId, COUNT(items.orderId) AS itemsCount
  FROM mydb.orders
  LEFT JOIN mydb.items ON orders.orderId = items.orderId
  GROUP BY orders.userId, orders.orderValue, orders.orderId) AS aggregatedOrders
ON users.id = aggregatedOrders.userId
LEFT JOIN mydb.stars ON users.id = stars.user_id
LEFT JOIN mydb.vipusers ON users.id = vipusers.id
GROUP BY users.id, users.user_name, users.city, is_vip;

-- COMMAND ----------

-- COMMAND ----------
CONTENT
}

resource "databricks_notebook" "create_engagement_table" {
  content_base64 = base64encode(local.create_engagement_table)
  language = "SQL"
  path   = "/Shared/create_engagement_table"
}
