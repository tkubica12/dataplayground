// SILVER-to-GOLD: User engagement table
locals {
  create_engagement_table = <<CONTENT
-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Precalculate User Engagement table

-- COMMAND ----------

CREATE OR REPLACE TABLE mycatalog.mydb.engagements
LOCATION 'abfss://gold@${var.storage_account_name}.dfs.core.windows.net/engagements'
AS
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
FROM mycatalog.mydb.users
LEFT JOIN hive_metastore.streaming.parsed_pageviews AS pageviews 
ON users.id = pageviews.user_id
LEFT JOIN (
  SELECT orders.userId, orders.orderValue, orders.orderId, COUNT(items.orderId) AS itemsCount
  FROM mycatalog.mydb.orders
  LEFT JOIN mycatalog.mydb.items ON orders.orderId = items.orderId
  GROUP BY orders.userId, orders.orderValue, orders.orderId) AS aggregatedOrders
ON users.id = aggregatedOrders.userId
LEFT JOIN hive_metastore.streaming.parsed_stars AS stars ON users.id = stars.user_id
LEFT JOIN mycatalog.mydb.vipusers ON users.id = vipusers.id
GROUP BY users.id, users.user_name, users.city, is_vip;

-- COMMAND ----------

-- COMMAND ----------
CONTENT
}

resource "databricks_notebook" "create_engagement_table" {
  content_base64 = base64encode(local.create_engagement_table)
  language       = "SQL"
  path           = "/Shared/create_engagement_table"
}

// ETL: Delta Live Tables
locals {
  delta_live_etl = <<CONTENT
-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Load users

-- COMMAND ----------

CREATE OR REFRESH STREAMING LIVE TABLE users
AS SELECT * FROM cloud_files("abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/users/", "json")

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Load VIP users

-- COMMAND ----------

CREATE OR REFRESH STREAMING LIVE TABLE vipusers
AS SELECT * FROM cloud_files("abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/vipusers/", "json")

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Load Products

-- COMMAND ----------

CREATE OR REFRESH STREAMING LIVE TABLE products
AS SELECT * FROM cloud_files("abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/products/", "json")

-- COMMAND ----------

CONTENT
}

resource "databricks_notebook" "delta_live_etl" {
  content_base64 = base64encode(local.delta_live_etl)
  language       = "SQL"
  path           = "/Shared/delta_live_etl"
}

// Display delta live tables
locals {
  delta_live_demo = <<CONTENT
-- Databricks notebook source
-- MAGIC %md 
-- MAGIC # Processing streaming data

-- COMMAND ----------

USE DATABASE streaming;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Get raw pageviews

-- COMMAND ----------

SELECT timestamp,
  get_json_object(CAST(value AS string), '$.user_id') AS user_id,
  get_json_object(CAST(value AS string), '$.http_method') AS http_method,
  get_json_object(CAST(value AS string), '$.uri') AS uri,
  get_json_object(CAST(value AS string), '$.client_ip') AS client_ip,
  get_json_object(CAST(value AS string), '$.user_agent') AS user_agent, 
  get_json_object(CAST(value AS string), '$.latency') AS latency 
FROM stream_pageviews

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## High latency alert

-- COMMAND ----------

SELECT * FROM 
(
  SELECT timestamp,
    get_json_object(CAST(value AS string), '$.user_id') AS user_id,
    get_json_object(CAST(value AS string), '$.http_method') AS http_method,
    get_json_object(CAST(value AS string), '$.uri') AS uri,
    get_json_object(CAST(value AS string), '$.client_ip') AS client_ip,
    get_json_object(CAST(value AS string), '$.user_agent') AS user_agent, 
    get_json_object(CAST(value AS string), '$.latency') AS latency 
  FROM stream_pageviews
)
AS parsed_pageviews 
WHERE parsed_pageviews.latency > 2000

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## High latency alert enriched

-- COMMAND ----------

SELECT * FROM 
(
  SELECT timestamp,
    get_json_object(CAST(value AS string), '$.user_id') AS user_id,
    get_json_object(CAST(value AS string), '$.http_method') AS http_method,
    get_json_object(CAST(value AS string), '$.uri') AS uri,
    get_json_object(CAST(value AS string), '$.client_ip') AS client_ip,
    get_json_object(CAST(value AS string), '$.user_agent') AS user_agent, 
    get_json_object(CAST(value AS string), '$.latency') AS latency 
  FROM stream_pageviews
)
AS parsed_pageviews 
LEFT JOIN mycatalog.mydb.users ON parsed_pageviews.user_id = mycatalog.mydb.users.id
WHERE parsed_pageviews.latency > 2000

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## VIP only pageviews

-- COMMAND ----------

SELECT * FROM 
(
  SELECT timestamp,
    get_json_object(CAST(value AS string), '$.user_id') AS user_id,
    get_json_object(CAST(value AS string), '$.http_method') AS http_method,
    get_json_object(CAST(value AS string), '$.uri') AS uri,
    get_json_object(CAST(value AS string), '$.client_ip') AS client_ip,
    get_json_object(CAST(value AS string), '$.user_agent') AS user_agent, 
    get_json_object(CAST(value AS string), '$.latency') AS latency 
  FROM stream_pageviews
)
AS parsed_pageviews 
INNER JOIN mycatalog.mydb.vipusers ON parsed_pageviews.user_id = mycatalog.mydb.vipusers.id

-- COMMAND ----------

CONTENT
}

resource "databricks_notebook" "delta_live_demo" {
  content_base64 = base64encode(local.delta_live_demo)
  language       = "SQL"
  path           = "/Shared/delta_live_demo"
}
