-- Databricks notebook source

-- COMMAND ----------

-- MAGIC %python
-- MAGIC spark.conf.set('demo.storage_account_name', dbutils.secrets.get(scope="azure", key="storage_account_name"))

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Precalculate User Engagement table

-- COMMAND ----------

CREATE OR REPLACE TABLE mycatalog.mydb.engagements
LOCATION 'abfss://gold@${demo.storage_account_name}.dfs.core.windows.net/engagements'
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


