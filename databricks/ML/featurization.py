# Databricks notebook source
# MAGIC %md
# MAGIC # Get aggregates from Delta tables

# COMMAND ----------

# MAGIC %sql
# MAGIC USE mycatalog.mydb;
# MAGIC 
# MAGIC CREATE OR REPLACE TEMP VIEW mydata AS
# MAGIC SELECT administrative_unit, 
# MAGIC       birth_number,
# MAGIC       users.id as user_id, 
# MAGIC       sum(orderValue) as total_orders_value, 
# MAGIC       iff(isnull(vipusers.id), false, true) AS is_vip
# MAGIC FROM users
# MAGIC LEFT JOIN orders ON users.id = orders.userId
# MAGIC LEFT JOIN vipusers ON users.id = vipusers.id
# MAGIC GROUP BY administrative_unit, birth_number, users.id, is_vip

# COMMAND ----------

df = spark.table("mydata")

display(df)


# COMMAND ----------

# MAGIC %md
# MAGIC # Featurization

# COMMAND ----------

from pyspark.sql.functions import substring, col, when, translate, regexp_replace

# COMMAND ----------

# MAGIC %md
# MAGIC Impute nulls

# COMMAND ----------

df = df.fillna(0, "total_orders_value")

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC Convert is_vip to 0 and 1

# COMMAND ----------

df = df.withColumn("is_vip", when(col("is_vip") == "true", 1).otherwise(0))

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC Calculate age group and sex from birth number

# COMMAND ----------

import datetime

# Get current year
current_year = datetime.datetime.now().date().year

# Convert to 2-digit year
current_year_2dig = int(str(current_year)[2:])

# Prepare data - first parse 2-digit year from birth number
# then convert 2-digit to 4-digit year
# then create dummy vars for category child, teenager and adult -> senior category is ommited as to break full corraltion and is therefore implicit
# then parse month from birth number
# then create is_woman feature -> man category is again ommited and therefore implicit

df = df.withColumn("birth_year_2dig", substring(col("birth_number"), 0, 2).cast("integer")) \
       .withColumn("birth_year", when(col("birth_year_2dig") > current_year_2dig, col("birth_year_2dig")+1900).otherwise(col("birth_year_2dig")+2000)) \
       .drop("birth_year_2dig") \
       .withColumn("is_child", when(col("birth_year") >= current_year-12, 1).otherwise(0)) \
       .withColumn("is_teenager", when((col("birth_year") >= current_year-18) & (col("birth_year") < current_year-12), 1).otherwise(0)) \
       .withColumn("is_adult", when((col("birth_year") >= current_year-65) & (col("birth_year") < current_year-18), 1).otherwise(0)) \
       .withColumn("month", substring(col("birth_number"), 3, 2).cast("integer")) \
       .withColumn("is_woman", when(col("month") > 12, 1).otherwise(0)) \
       .drop("month")

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC Remove special characters from administrative_unit

# COMMAND ----------

df = df.withColumn("administrative_unit", translate(col("administrative_unit"), "áéěůúóíýžščřďťňÁÉĚŮÚÓÍÝŽŠČŘĎŤŇ", "aeeuuoiyzscrdtnAEEUUOIYZSCRDTN")) \
       .withColumn("administrative_unit", regexp_replace(col("administrative_unit"), " kraj", "")) \
       .withColumn("administrative_unit", regexp_replace(col("administrative_unit"), "Kraj ", ""))

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC Create dummy vars for administrative units

# COMMAND ----------

import pyspark.pandas as ps
df_ps = ps.DataFrame(df)
df = ps.get_dummies(data=df_ps, columns=["administrative_unit"], drop_first=True, dtype="int").to_spark()

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC Drop what is not feature, but keep id

# COMMAND ----------

df = df.drop("birth_number", "birth_year")

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC # Store data in Feature Store

# COMMAND ----------

from databricks import feature_store

fs = feature_store.FeatureStoreClient()

spark.sql("CREATE DATABASE IF NOT EXISTS hive_metastore.features")

fs.create_table(name="hive_metastore.features.users", primary_keys="user_id", schema=df.schema, description="Features for users based on user_id")
fs.write_table(name="hive_metastore.features.users", df=df, mode="overwrite")

# COMMAND ----------


