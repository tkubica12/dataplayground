- [Delta in Python](#delta-in-python)
- [Data preparation](#data-preparation)
- [Data split](#data-split)
  - [Random split 80/20](#random-split-8020)

# Delta in Python

```python
# Read Parquet from file
my_df = spark.read.format("parquet").load(file_path)

# Read CSV from file
my_df = spark.read.csv(file_path, header="true", inferSchema="true", multiLine="true", escape='"')

df = spark.read \
    .option("inferSchema", "true") \
    .option("delimiter",":") \
    .option("header","true") \
    .csv(source_file)

    
# Directly write df as Delta files
my_df.write.format("delta").mode("overwrite").save(directory_path)

# Register Delta table and write to it
spark.sql(f"CREATE DATABASE IF NOT EXISTS {DA.cleaned_username}")
spark.sql(f"USE {DA.cleaned_username}")
my_df.write.format("delta").mode("overwrite").saveAsTable("my_table")

# Write partitioned Delta table
my_df.write
    .format("delta")
    .mode("overwrite")
    .partitionBy("my_column")
    .option("overwriteSchema", "true")
    .save(directory_path)

# Update
my_df_update = my_df.filter(my_df["my_column"] == "my_value")
df_update.write.format("delta").mode("overwrite").save(directory_path)

# Versioning
my_df = spark.read.format("delta").option("versionAsOf", 0).load(directory_path)
my_df = spark.read.format("delta").option("timestampAsOf", my_timestamp).load(directory_path)

# Vacuum
from delta.tables import DeltaTable

spark.conf.set("spark.databricks.delta.retentionDurationCheck.enabled", "false")
delta_table = DeltaTable.forPath(spark, directory_path)
delta_table.vacuum(0)
```

# Data preparation

```python
# Select just certain columns
my_df = raw_df.select(["beds","bed_type"])

# Parse price from string (remove $ and , and cast to double)
fixed_price_df = base_df.withColumn("price", translate(col("price"), "$,", "").cast("double"))

# Convert feature to log and prediction back (exp)
log_train_df = train_df.withColumn("logPrice", log("price"))
exp_df = pred_df.withColumn("label", exp(col("label"))).withColumn("prediction", exp(col("prediction")))

# Feature stats
display(fixed_price_df.describe())      # count, mean, min, max, std dev
display(fixed_price_df.summary())       # count, mean, min, max, std dev, 25%, 50%, 75%
dbutils.data.summarize(fixed_price_df)  # more stats about features including charts, zero/nulls, etc.

# Keep only items priced > 0
pos_prices_df = fixed_price_df.filter(col("price") > 0)

# Aggregate count based on categorical feature
display(pos_prices_df
        .groupBy("minimum_nights")
        .count()
        .orderBy(col("count").desc(), col("minimum_nights"))
       )

# WHERE
display(imputed_df.where((imputed_df["beds_na"] == 0) & (imputed_df["beds"] == 1))[["beds", "beds_na"]])
```

Handling nulls
- Drop any records that contain nulls
- Numeric:
    - Replace them with mean/median/zero/etc.
- Categorical:
    - Replace them with the mode
    - Create a special category for null
- Use techniques like ALS (Alternating Least Squares) which are designed to impute missing values

If you do ANY imputation techniques for categorical/numerical features, you MUST include an additional field specifying that field was imputed.

```python
from pyspark.ml.feature import Imputer

imputer = Imputer(strategy="median", inputCols=impute_cols, outputCols=impute_cols)

imputer_model = imputer.fit(doubles_df)
imputed_df = imputer_model.transform(doubles_df)
```

# Data split

## Random split 80/20

```python
train_df, test_df = airbnb_df.randomSplit([.8, .2], seed=42)
```
