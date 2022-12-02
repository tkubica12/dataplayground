# Databricks notebook source
# MAGIC %md
# MAGIC # Batch inferencing demo

# COMMAND ----------

# MAGIC %md
# MAGIC Let's generate df with new data on which we want to predict order value.
# MAGIC 
# MAGIC We will have few existing users and we want to predict their order value for Tuesday in December.

# COMMAND ----------

from pyspark.sql.types import StructType,StructField, StringType, IntegerType

data = [(101,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1),
    (220,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1),
    (333,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1),
    (412,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1),
    (555,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1)
  ]

schema = StructType([ \
    StructField("user_id",IntegerType(),True), \
    StructField("dayofweek_2",IntegerType(),True), \
    StructField("dayofweek_3",IntegerType(),True), \
    StructField("dayofweek_4",IntegerType(),True), \
    StructField("dayofweek_5",IntegerType(),True), \
    StructField("dayofweek_6",IntegerType(),True), \
    StructField("dayofweek_7",IntegerType(),True), \
    StructField("month_2",IntegerType(),True), \
    StructField("month_3",IntegerType(),True), \
    StructField("month_4",IntegerType(),True), \
    StructField("month_5",IntegerType(),True), \
    StructField("month_6",IntegerType(),True), \
    StructField("month_7",IntegerType(),True), \
    StructField("month_8",IntegerType(),True), \
    StructField("month_9",IntegerType(),True), \
    StructField("month_10",IntegerType(),True), \
    StructField("month_11",IntegerType(),True), \
    StructField("month_12",IntegerType(),True), \
    StructField("timeofday_morning",IntegerType(),True), \
    StructField("timeofday_day",IntegerType(),True), \
    StructField("timeofday_evening",IntegerType(),True), \
  ])
 
df = spark.createDataFrame(data=data,schema=schema)

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC Lookup user features from feature store

# COMMAND ----------

from databricks import feature_store
from pyspark.sql.functions import lit

fs = feature_store.FeatureStoreClient()

df = df.withColumn("order_id", lit(0))

predictions = fs.score_batch(
    'models:/order_value/10',
    df
)

display(predictions)

# COMMAND ----------


