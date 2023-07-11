-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Gold engagements table

-- COMMAND ----------
CREATE OR REFRESH LIVE TABLE engagements
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
FROM live.stream_users AS users
LEFT JOIN live.parsed_pageviews AS pageviews 
ON users.id = pageviews.user_id
LEFT JOIN (
  SELECT orders.userId, orders.orderValue, orders.orderId, COUNT(items.orderId) AS itemsCount
  FROM live.stream_orders AS orders
  LEFT JOIN live.stream_items AS items
  ON orders.orderId = items.orderId
  GROUP BY orders.userId, orders.orderValue, orders.orderId) AS aggregatedOrders
ON users.id = aggregatedOrders.userId
LEFT JOIN live.parsed_stars AS stars ON users.id = stars.user_id
LEFT JOIN live.stream_vipusers AS vipusers ON users.id = vipusers.id
GROUP BY users.id, users.user_name, users.city, is_vip;
