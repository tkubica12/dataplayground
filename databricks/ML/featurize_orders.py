# Databricks notebook source
# MAGIC %md
# MAGIC # Featurize orders information
# MAGIC - Day of the week of purchase as OHE
# MAGIC - Month of purchase as OHE
# MAGIC - Daytime category as OHE
# MAGIC - Order value

# COMMAND ----------

# MAGIC %md
# MAGIC ## Get data from orders table, calculate dayofweek, month and hour

# COMMAND ----------

# MAGIC %sql
# MAGIC USE mycatalog.mydb;
# MAGIC 
# MAGIC CREATE OR REPLACE TEMP VIEW mydata AS
# MAGIC SELECT orderId, userId, orderValue, dayofweek(orderDate) as dayofweek, month(orderDate) as month, hour(orderDate) as hour
# MAGIC FROM orders

# COMMAND ----------

df = spark.table("mydata")

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Featurization

# COMMAND ----------

from pyspark.sql.functions import col, when

# COMMAND ----------

# MAGIC %md
# MAGIC Make dayofweek and month dummy variable

# COMMAND ----------

import pyspark.pandas as ps
df_ps = ps.DataFrame(df)
df = ps.get_dummies(data=df_ps, columns=["dayofweek", "month"], drop_first=True, dtype="int").to_spark()

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC Create time of day catories

# COMMAND ----------

df = df.withColumn("timeofday_morning", when((col("hour") >= 6) & (col("hour") < 10), 1).otherwise(0)) \
        .withColumn("timeofday_day", when((col("hour") >= 10) & (col("hour") < 17), 1).otherwise(0)) \
        .withColumn("timeofday_evening", when((col("hour") >= 17) & (col("hour") < 22), 1).otherwise(0)) \
        .drop("hour")

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Store data in Feature Store

# COMMAND ----------

from databricks import feature_store

fs = feature_store.FeatureStoreClient()

spark.sql("CREATE DATABASE IF NOT EXISTS hive_metastore.features")

fs.create_table(name="hive_metastore.features.orders", primary_keys="orderId", schema=df.schema, description="Features for orders")
fs.write_table(name="hive_metastore.features.orders", df=df, mode="overwrite")
