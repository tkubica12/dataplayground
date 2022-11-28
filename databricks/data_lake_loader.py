# Databricks notebook source

# COMMAND ----------

storage_account_name = dbutils.secrets.get(scope="azure", key="storage_account_name")

# COMMAND ----------

# MAGIC %md
# MAGIC # Users

# COMMAND ----------

data_path = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/users/"
checkpoint_path = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/_checkpoint/users"

(spark.readStream
  .format("cloudFiles")
  .option("cloudFiles.format", "json")
  .option("cloudFiles.schemaLocation", checkpoint_path)
  .load(data_path)
  .writeStream
  .option("checkpointLocation", checkpoint_path)
  .trigger(availableNow=True)
  .toTable("mycatalog.mydb.users"))

# COMMAND ----------

# MAGIC %md
# MAGIC # VIP Users

# COMMAND ----------

data_path = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/vipusers/"
checkpoint_path = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/_checkpoint/vipusers"

(spark.readStream
  .format("cloudFiles")
  .option("cloudFiles.format", "json")
  .option("cloudFiles.schemaLocation", checkpoint_path)
  .load(data_path)
  .writeStream
  .option("checkpointLocation", checkpoint_path)
  .trigger(availableNow=True)
  .toTable("mycatalog.mydb.vipusers"))

# COMMAND ----------

# MAGIC %md
# MAGIC # Products

# COMMAND ----------

data_path = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/products/"
checkpoint_path = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/_checkpoint/products"

(spark.readStream
  .format("cloudFiles")
  .option("cloudFiles.format", "json")
  .option("cloudFiles.schemaLocation", checkpoint_path)
  .load(data_path)
  .writeStream
  .option("checkpointLocation", checkpoint_path)
  .trigger(availableNow=True)
  .toTable("mycatalog.mydb.products"))
