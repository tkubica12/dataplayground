- [Delta in Python](#delta-in-python)
- [Data preparation with DataFrame API](#data-preparation-with-dataframe-api)
- [Using Pandas in Spark](#using-pandas-in-spark)
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

    
# Directly write DataFrame as Delta files
my_df.write.format("delta").mode("overwrite").save(directory_path)

# Create temp view out of DataFrame
budget_df.createOrReplaceTempView("budget")

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

# Data preparation with DataFrame API

```python
# Select just certain columns
my_df = raw_df.select(["beds","bed_type"])

# Schema
my_df.schema
my_df.printSchema()

# SELECT .. WHERE
my_df.select("col1", "col2").where("col2 < 200").orderBy("col2")

# Collect values from DataFrame
for row in budget_df.select("price").collect():
    print(row["price"])

# Parse price from string (remove $ and , using translate function and cast to double)
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
- Use techniques like ALS (Alternating Least Squares) wh_ich are designed to impute missing values

If you do ANY imputation techniques for categorical/numerical features, you MUST include an additional field specifying that field was imputed.

```python
from pyspark.ml.feature import Imputer

imputer = Imputer(strategy="median", inputCols=impute_cols, outputCols=impute_cols)

imputer_model = imputer.fit(doubles_df)
imputed_df = imputer_model.transform(doubles_df)
```

For **advanced manipulation** on data in column we can use lambda. In this example we have values "t" and "f" in column and we want to convert this to 0 and 1.

```python
# Define regular function
def boolstring_to_number(x):
    if x == "t":
        return 1
    else:
        return 0

# Use it in UDF with lambda
boolstring_to_number_udf = udf(lambda x : bool_to_number(x))

# Then use this logic on values in column
label_df = airbnb_df.withColumn("label", boolstring_to_number_udf(col("host_is_superhost")).cast('float'))
```

# Using Pandas in Spark
Pandas is ery popular Python library for data manipulation and analysis. Unfortunatelly does not scale to Big Data so project Koalas was created to bring Pandas to Spark and leverage distributed computing. This project became park of PySpark 3.2 as in now native part of Spark as "Pandas API". 
- Pandas -> will run on driver only, does not take advantage of cluster
- Spark Pandas API -> Pandas-compatible API (formaly Koalas) to basically run Pandas commands on top of Spark DataFrame therefore leveraging distributed capabilities of Spark while not having to rewrite data manipulation code
- Spark DataFrame API -> Native Spark API to do similar things (data transformation, filtering, data preparation, imputation etc.) - different from Pandas so if you have Pandas code developed on local machine you need to rewrite
- Pandas UDF -> You can define Pandas function (some processing logic such as in previous chapter - convert "t" to 1 and "f" to 0) as UDF and use it to process data in Spark DataFrame (eg. using withColumn)

```python
# Read Parquet file as Spark DataFrame
spark_df = spark.read.parquet(f"{DA.paths.datasets}/airbnb/sf-listings/sf-listings-2019-03-06-clean.parquet/")

# Read Parquet file as traditional Pandas DataFrame
import pandas as pd
pandas_df = pd.read_parquet(f"{DA.paths.datasets.replace('dbfs:/', '/dbfs/')}/airbnb/sf-listings/sf-listings-2019-03-06-clean.parquet/")

# Read Parquet file with Spark Pandas API (formerly Koalas)
import pyspark.pandas as ps
df = ps.read_parquet(f"{DA.paths.datasets}/airbnb/sf-listings/sf-listings-2019-03-06-clean.parquet/")

# Convert Spark DataFrame to Spark Pandas API (two options)
df = ps.DataFrame(spark_df)
df = spark_df.to_pandas_on_spark()

# Convert Spark Pandas API to Spark DataFrame
df.to_spark()

# Example - count by group Spark vs. Pandas API on Spark
spark_df.groupby("property_type").count().orderBy("count", ascending=False)
df["property_type"].value_counts()

# With Spark API you can use popular visualisation libraries like Matplotlib
df.plot(kind="hist", x="bedrooms", y="price", bins=200)

# Using Pandas SQL on Pandas API on Spark DataFrame
ps.sql("SELECT distinct(property_type) FROM {df}", df=df)
```



```python
# Train
import mlflow.sklearn
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split

with mlflow.start_run(run_name="sklearn-random-forest") as run:
    # Enable autologging 
    mlflow.sklearn.autolog(log_input_examples=True, log_model_signatures=True, log_models=True)
    # Import the data
    df = pd.read_csv(f"{DA.paths.datasets}/airbnb/sf-listings/airbnb-cleaned-mlflow.csv".replace("dbfs:/", "/dbfs/")).drop(["zipcode"], axis=1)
    X_train, X_test, y_train, y_test = train_test_split(df.drop(["price"], axis=1), df[["price"]].values.ravel(), random_state=42)

    # Create model
    rf = RandomForestRegressor(n_estimators=100, max_depth=10, random_state=42)
    rf.fit(X_train, y_train)

# LInferencing
spark_df = spark.createDataFrame(X_test)
from typing import Iterator, Tuple

@pandas_udf("double")
def predict(iterator: Iterator[pd.DataFrame]) -> Iterator[pd.Series]:
    model_path = f"runs:/{run.info.run_id}/model" 
    model = mlflow.sklearn.load_model(model_path) # Load model
    for features in iterator:
        pdf = pd.concat(features, axis=1)
        yield pd.Series(model.predict(pdf))

prediction_df = spark_df.withColumn("prediction", predict(*spark_df.columns))
display(prediction_df)

# More efficient inferencing (will reuse model model from memory rather than loading it again)
predict_function = mlflow.pyfunc.spark_udf(spark, model_path)
features = X_train.columns
display(spark_df.withColumn("prediction", predict_function(*features)))

# Directly calling Pandas API on PySpark DataFrame
def predict(iterator: Iterator[pd.DataFrame]) -> Iterator[pd.DataFrame]:
    model_path = f"runs:/{run.info.run_id}/model" 
    model = mlflow.sklearn.load_model(model_path) # Load model
    for features in iterator:
        yield pd.concat([features, pd.Series(model.predict(features), name="prediction")], axis=1)
    
display(spark_df.mapInPandas(predict, """`host_total_listings_count` DOUBLE,`neighbourhood_cleansed` BIGINT,`latitude` DOUBLE,`longitude` DOUBLE,`property_type` BIGINT,`room_type` BIGINT,`accommodates` DOUBLE,`bathrooms` DOUBLE,`bedrooms` DOUBLE,`beds` DOUBLE,`bed_type` BIGINT,`minimum_nights` DOUBLE,`number_of_reviews` DOUBLE,`review_scores_rating` DOUBLE,`review_scores_accuracy` DOUBLE,`review_scores_cleanliness` DOUBLE,`review_scores_checkin` DOUBLE,`review_scores_communication` DOUBLE,`review_scores_location` DOUBLE,`review_scores_value` DOUBLE, `prediction` DOUBLE""")) 
```


# Data split

## Random split 80/20

```python
train_df, test_df = airbnb_df.randomSplit([.8, .2], seed=42)
```
