// SILVER-to-GOLD: User engagement table
# locals {
#   create_engagement_table = <<CONTENT
# -- Databricks notebook source
# -- MAGIC %md
# -- MAGIC # Precalculate User Engagement table

# -- COMMAND ----------

# CREATE OR REPLACE TABLE mycatalog.mydb.engagements
# LOCATION 'abfss://gold@${var.storage_account_name}.dfs.core.windows.net/engagements'
# AS
# SELECT users.id, 
#   users.user_name, 
#   users.city, 
#   COUNT(pageviews.user_id) AS pageviews, 
#   COUNT(aggregatedOrders.userId) AS orders,
#   SUM(aggregatedOrders.orderValue) AS total_orders_value,
#   AVG(aggregatedOrders.orderValue) AS avg_order_value,
#   SUM(aggregatedOrders.itemsCount) AS total_items,
#   AVG(stars.stars) AS avg_stars,
#   iff(isnull(vipusers.id), false, true) AS is_vip
# FROM mycatalog.mydb.users
# LEFT JOIN hive_metastore.streaming.parsed_pageviews AS pageviews 
# ON users.id = pageviews.user_id
# LEFT JOIN (
#   SELECT orders.userId, orders.orderValue, orders.orderId, COUNT(items.orderId) AS itemsCount
#   FROM mycatalog.mydb.orders
#   LEFT JOIN mycatalog.mydb.items ON orders.orderId = items.orderId
#   GROUP BY orders.userId, orders.orderValue, orders.orderId) AS aggregatedOrders
# ON users.id = aggregatedOrders.userId
# LEFT JOIN hive_metastore.streaming.parsed_stars AS stars ON users.id = stars.user_id
# LEFT JOIN mycatalog.mydb.vipusers ON users.id = vipusers.id
# GROUP BY users.id, users.user_name, users.city, is_vip;

# -- COMMAND ----------

# -- COMMAND ----------
# CONTENT
# }

# resource "databricks_notebook" "create_engagement_table" {
#   content_base64 = base64encode(local.create_engagement_table)
#   language       = "SQL"
#   path           = "/Shared/create_engagement_table"
# }


// Jobs
resource "databricks_job" "engagement_table" {
  name = "engagement_table"

  existing_cluster_id = databricks_cluster.single_user_cluster.id

  schedule {
    quartz_cron_expression = "0 */50 * ? * *"
    timezone_id            = "UTC"
  }

  notebook_task {
    notebook_path = "${databricks_repo.main.path}/create_engagement_table"
  }
}


