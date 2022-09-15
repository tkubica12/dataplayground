// Create Delta Lake
locals {
  createdeltalake = <<CONTENT
-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Create Delta tables in Unity Catalog from Data Lake files using managed identity authentication

-- COMMAND ----------

USE CATALOG mycatalog;

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS mydb.products
(
  description STRING,
  id BIGINT,
  name STRING,
  pages ARRAY<STRING>
);

GRANT ALL PRIVILEGES ON TABLE mydb.products TO `account users`;

COPY INTO mydb.products
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/products/'  WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = JSON;

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS mydb.vipusers
(
  id BIGINT
);

GRANT ALL PRIVILEGES ON TABLE mydb.vipusers TO `account users`;

COPY INTO mydb.vipusers
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/users/vip.json' WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = JSON;

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS mydb.users
(
  administrative_unit STRING,
  birth_number STRING,
  city STRING,
  description STRING,
  id BIGINT,
  jobs ARRAY<STRING>,
  name STRING,
  phone_number STRING,
  street_address STRING,
  user_name STRING
);

GRANT ALL PRIVILEGES ON TABLE mydb.users TO `account users`;

COPY INTO mydb.users
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/users/users.json'  WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = JSON;

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS mydb.orders
(
  orderId INT,
  userId INT,
  orderDate TIMESTAMP,
  orderValue DOUBLE
);

GRANT ALL PRIVILEGES ON TABLE mydb.orders TO `account users`;

COPY INTO mydb.orders
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/orders/fromDataFactory.parquet'  WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = PARQUET;

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS mydb.items
(
  orderId INT,
  rowId INT,
  productId INT
);

GRANT ALL PRIVILEGES ON TABLE mydb.items TO `account users`;

COPY INTO mydb.items
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/items/fromDataFactory.parquet'  WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = PARQUET;

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS mydb.pageviews
(
  user_id BIGINT,
  http_method STRING,
  uri STRING,
  client_ip STRING,
  user_agent STRING,
  latency DOUBLE,
  EventProcessedUtcTime TIMESTAMP,
  PartitionId BIGINT,
  EventEnqueuedUtcTime TIMESTAMP,
  year INT,
  month INT,
  day INT
);

GRANT ALL PRIVILEGES ON TABLE mydb.pageviews TO `account users`;

COPY INTO mydb.pageviews
FROM 'abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/streamanalytics/pageviews/'  WITH (
  CREDENTIAL `mi_credential`
)
FILEFORMAT = PARQUET;

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS mydb.stars
(
  user_id BIGINT,
  stars BIGINT,
  EventProcessedUtcTime TIMESTAMP,
  PartitionId BIGINT,
  EventEnqueuedUtcTime TIMESTAMP,
  year INT,
  month INT,
  day INT
);

GRANT ALL PRIVILEGES ON TABLE mydb.stars TO `account users`;

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
  language       = "SQL"
  path           = "/Shared/CreateDeltaLake"
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
  language       = "SQL"
  path           = "/Shared/ExampleQueries"
}


// User engagement table
locals {
  create_engagement_table = <<CONTENT
-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Precalculate User Engagement table
-- COMMAND ----------

USE CATALOG mycatalog;
USE SCHEMA mydb;

-- COMMAND ----------

REPLACE TABLE engagements
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
  language       = "SQL"
  path           = "/Shared/create_engagement_table"
}

// Traditional streaming
locals {
  traditional_streaming = <<CONTENT
-- Databricks notebook source

-- MAGIC %md 
-- MAGIC # Traditional streaming

-- COMMAND ----------

from pyspark.sql.functions import *
from pyspark.sql.types import *

connectionString = "Endpoint=sb://lizdxifgxjqo.servicebus.windows.net/;SharedAccessKeyName=pageviewsReceiver;SharedAccessKey=5vDdfco3KSDwj/x2QI+/Phv6fBp9rFE+vw2uyLXbF1c=;EntityPath=pageviews"

ehConf = {}

ehConf['eventhubs.connectionString'] = connectionString
ehConf['eventhubs.consumerGroup'] = "databricks"
ehConf['eventhubs.connectionString'] = sc._jvm.org.apache.spark.eventhubs.EventHubsUtils.encrypt(connectionString)

df = spark \
  .readStream \
  .format("eventhubs") \
  .options(**ehConf) \
  .load()

df.createOrReplaceTempView('pageviews')

-- COMMAND ----------

%sql
SELECT CAST(body AS string) FROM pageviews

-- COMMAND ----------

CONTENT
}

resource "databricks_notebook" "traditional_streaming" {
  content_base64 = base64encode(local.traditional_streaming)
  language       = "PYTHON"
  path           = "/Shared/traditional_streaming"
}

// Delta Live Tables
locals {
  delta_live_stream = <<CONTENT
import dlt
from pyspark.sql.functions import *
from pyspark.sql.types import *

@dlt.table
def stream_pageviews():
    connection = 'kafkashaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="Endpoint=sb://${var.eventhub_namespace_name}.servicebus.windows.net/;SharedAccessKeyName=pageviewsReceiver;SharedAccessKey=${azurerm_eventhub_authorization_rule.pageviewsSender.primary_key}";'

    kafka_options = {
     "kafka.bootstrap.servers": "${var.eventhub_namespace_name}.servicebus.windows.net:9093",
     "kafka.sasl.mechanism": "PLAIN",
     "kafka.security.protocol": "SASL_SSL",
     "kafka.request.timeout.ms": "60000",
     "kafka.session.timeout.ms": "30000",
     "startingOffsets": "earliest",
     "kafka.sasl.jaas.config": connection,
     "subscribe": "pageviews",
      }
    return spark.readStream.format("kafka").options(**kafka_options).load()

CONTENT
}

resource "databricks_notebook" "delta_live_stream" {
  content_base64 = base64encode(local.delta_live_stream)
  language       = "PYTHON"
  path           = "/Shared/delta_live_stream"
}

// Display delta live tables
locals {
  delta_live_demo = <<CONTENT
-- Databricks notebook source

-- MAGIC %md 
-- MAGIC # Delta Live Tables

-- COMMAND ----------

USE DATABASE mydb2;

-- COMMAND ----------

SELECT * FROM eventhubs_pageviews

-- COMMAND ----------

CONTENT
}

resource "databricks_notebook" "delta_live_demo" {
  content_base64 = base64encode(local.delta_live_demo)
  language       = "SQL"
  path           = "/Shared/delta_live_demo"
}
