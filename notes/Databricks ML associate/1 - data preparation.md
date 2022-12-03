- [Delta in Python](#delta-in-python)
- [Data preparation with DataFrame API](#data-preparation-with-dataframe-api)
  - [Basic operations](#basic-operations)
  - [Date time functions](#date-time-functions)
  - [String functions](#string-functions)
  - [Collection functions](#collection-functions)
  - [Handling missing values](#handling-missing-values)
  - [Advanced manipulation with UDFs](#advanced-manipulation-with-udfs)
- [Using Pandas in Spark](#using-pandas-in-spark)
- [Data split](#data-split)

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

## Basic operations

```python
# Select just certain columns
my_df = raw_df.select(["beds","bed_type"])

# Schema
my_df.schema
my_df.printSchema()

# SELECT .. WHERE (note DataFrame where is alias for filter)
my_df.select("col1", "col2", col("col3.subitem".alias("col3s")).where("col2 < 200").orderBy("col2")

# SELECT ... WHERE by creating temp and using regular SQL
my_df.createOrReplaceTempView("my")
spark.sql("SELECT col1, col2, col3.subitem AS col3d FROM my WHERE col2 < 200 ORDER BY col2")

# selectExpr() can use expressions on column, such as get true if device in macOS, iOS
events_df.selectExpr("user_id", "device in ('macOS', 'iOS') as apple_user")

# The same result using withColumn()
events_df.withColumn("apple_user", col("device").isin('macOS', 'iOS')).select("user_id", "apple_user")

# Collect values from DataFrame
for row in budget_df.select("price").collect():
    print(row["price"])

# Parse price from string (remove $ and , using translate function and cast to double)
fixed_price_df = base_df.withColumn("price", translate(col("price"), "$,", "").cast("double"))

# Convert feature to log and prediction back (exp)
log_train_df = train_df.withColumn("logPrice", log("price"))
exp_df = pred_df.withColumn("label", exp(col("label"))).withColumn("prediction", exp(col("prediction")))

# Add column with literal value (eg. good for reference model that always answers 0)
from pyspark.sql.functions import lit
events_df.withColumn("prediction", lit(0))

# Drop column
events_df.drop("items")

# Deduplicate (note distinct is alias for dropDuplicates)
events_df.distinct()

# Feature stats
display(fixed_price_df.describe())      # count, mean, min, max, std dev
display(fixed_price_df.summary())       # count, mean, min, max, std dev, 25%, 50%, 75%
dbutils.data.summarize(fixed_price_df)  # more stats about features including charts, zero/nulls, etc.

# Keep only items priced > 0
pos_prices_df = fixed_price_df.filter(col("price") > 0)

# Aggregate count based on categorical feature
pos_prices_df.groupBy("minimum_nights").count().orderBy(col("count").desc(), col("minimum_nights"))

# Aggregate average revenue by state
df.groupBy("geo.state").avg("ecommerce.purchase_revenue_in_usd")

# Multiple different aggregations with agg()
df.groupBy("geo.state").agg(avg("revenue").alias("avg_revenue"),approx_count_distinct("user_id").alias("distinct_users"))

# WHERE
display(imputed_df.where((imputed_df["beds_na"] == 0) & (imputed_df["beds"] == 1))[["beds", "beds_na"]])
```

## Date time functions
| Method | Description |
| --- | --- |
| **`add_months`** | Returns the date that is numMonths after startDate |
| **`current_timestamp`** | Returns the current timestamp at the start of query evaluation as a timestamp column |
| **`date_format`** | Converts a date/timestamp/string to a value of string in the format specified by the date format given by the second argument. |
| **`dayofweek`** | Extracts the day of the month as an integer from a given date/timestamp/string |
| **`from_unixtime`** | Converts the number of seconds from unix epoch (1970-01-01 00:00:00 UTC) to a string representing the timestamp of that moment in the current system time zone in the yyyy-MM-dd HH:mm:ss format |
| **`minute`** or second, dayofweek, month, year, ... | Extracts the minutes as an integer from a given date/timestamp/string. |
| **`unix_timestamp`** | Converts time string with given pattern to Unix timestamp (in seconds) |

## String functions
| Method | Description |
| --- | --- |
| translate | Translate any character in the src by a character in replaceString |
| regexp_replace | Replace all substrings of the specified string value that match regexp with rep |
| regexp_extract | Extract a specific group matched by a Java regex, from the specified string column |
| ltrim | Removes the leading space characters from the specified string column |
| lower | Converts a string column to lowercase |
| split | Splits str around matches of the given pattern |

## Collection functions
| Method | Description |
| --- | --- |
| array_contains | Returns null if the array is null, true if the array contains value, and false otherwise. |
| element_at | Returns element of array at given index. Array elements are numbered starting with **1**. |
| explode | Creates a new row for each element in the given array or map column. |
| collect_set | Returns a set of objects with duplicate elements eliminated. |

## Handling missing values
- Always drop raws missing label (y ... the thing you are going to predict)
- Features with a lot of nulls might not add value, drop column
- Features with few nulls
  - If row is missing multiple features it might be better to drop the row
  - Complete Case Analysis is strategy to drop all rows containing any nulls -> important to note is that missing values are due to randomness - Missing At Random (there is no hidden information in missing values such as "did not want to respond") and we still have enough data after this operation (eg. drop less than 5%)
  - If row is missing just one feature it might be better to impute value as dropping row is information loss
    - Numeric:
        - Mean
        - Median
        - Zero or some other arbitrary value (eg. 37 degrees Celsius for human body measurement)
    - Categorical:
        - Most frequent (mode)
        - Special category for null (can be useful when it actually represents some decision rather than quality issue, eg. sex being male, female and "did not answer" or "not applicable"). If null actually holds information value than dropping such rows might introduce bias.
    - There are advanced methods such as ALS (Alternating Least Squares), KNN, MICE or even using Deep Learning to impute (calculate missing values based on other features in dataset)

If you do any imputation techniques for categorical/numerical features, you should include an additional field specifying that field was imputed.

```python
from pyspark.ml.feature import Imputer

imputer = Imputer(strategy="median", inputCols=impute_cols, outputCols=impute_cols)

imputer_model = imputer.fit(doubles_df)
imputed_df = imputer_model.transform(doubles_df)
```

## Advanced manipulation with UDFs
For advanced manipulation on data in column we can use lambda. In this example we have values "t" and "f" in column and we want to convert this to 0 and 1. Note Python UDFs are **slow** - prefer using standard Spark functions or use Pandas UDFs which are better performing (via using Arrow).

```python
# Define regular function
def boolstring_to_number(x):
    if x == "t":
        return 1
    else:
        return 0

# Make it UDF
boolstring_to_number_udf = udf(boolstring_to_number)

# Then use this logic on values in column
label_df = airbnb_df.withColumn("label", boolstring_to_number_udf(col("host_is_superhost")).cast('float'))
```

We can also use decorator to define function as UDF. Advantage is we can give typehint so UDF returns float (no need to cast as in previous example)

```python
@udf("float")
def boolstring_to_number_udf(x) -> float:
    if x == "t":
        return 1
    else:
        return 0
```

This task can be achieved much more efficiently using pyspark functions so make sure you use UDFs only when neccessary.

```python
from pyspark.sql.functions import when
label_df = airbnb_df.withColumn("label", when(col("host_is_superhost") == "t", 1).otherwise(0).cast("float"))
```

UDFs can also be registered for use in SQL.

```python
boolstring_to_number_udf = spark.udf.register("sql_udf", bool_to_number)
```

```sql
select id, boolstring_to_number_udf(host_is_superhost) as label from table
```

# Using Pandas in Spark
Pandas is ery popular Python library for data manipulation and analysis. Unfortunatelly does not scale to Big Data so project Koalas was created to bring Pandas to Spark and leverage distributed computing. This project became park of PySpark 3.2 as in now native part of Spark as "Pandas API". 
- Pandas -> will run on driver only, does not take advantage of cluster
- Spark Pandas API -> Pandas-compatible API (formaly Koalas) to basically run Pandas commands on top of Spark DataFrame therefore leveraging distributed capabilities of Spark while not having to rewrite data manipulation code
- Spark DataFrame API -> Native Spark API to do similar things (data transformation, filtering, data preparation, imputation etc.) - different from Pandas so if you have Pandas code developed on local machine you need to rewrite
- Pandas UDF -> You can define Pandas function (some processing logic such as in previous chapter - convert "t" to 1 and "f" to 0) as UDF and use it to process data in Spark DataFrame (eg. using withColumn)

Performance wise:
Spark DataFrame > Spark Pandas API > Pandas UDF > Pandas

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

# Example - use Pandas API get_dummies function
df_ps = ps.DataFrame(df)
df = ps.get_dummies(data=df_ps, columns=["administrative_unit"], drop_first=True).to_spark()

# Example - count by group Spark vs. Pandas API on Spark
spark_df.groupby("property_type").count().orderBy("count", ascending=False)
df["property_type"].value_counts()

# With Spark API you can use popular visualisation libraries like Matplotlib
df.plot(kind="hist", x="bedrooms", y="price", bins=200)

# Using Pandas SQL on Pandas API on Spark DataFrame
ps.sql("SELECT distinct(property_type) FROM {df}", df=df)
```

Here is example of Pandas UDF used for inferencing.

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

# Inferencing
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

# More efficient inferencing (will reuse model model from memory rather than loading it again for every batch)
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
This how to split data in Spark. Note seed is used to get the same results everz time, but since Spark is distributed this is not enough. Actual result also depends on number of partitions which are by default based on size of cluster.

```python
# Repartition DataFrame if you need repeatability across different cluster configurations
airbnb_df.repartition(24)

# Split data
train_df, test_df = airbnb_df.randomSplit([.8, .2], seed=42)
```

Note this is different with sklearn that is often used for dev and single-node scenarios (eg. multi-node deep learning is difficult and very often people use just single GPU-enabled node).

```python
# Split with sklearn
from sklearn.model_selection import train_test_split
train, test = train_test_split(df, test_size=0.2, random_state=0)

# In spark features are vectorized a part of the same DataFrame
# In other frameworks such as Tensorflow you typicaly have separatae DataFrame for features and labels
X_train, X_test, y_train, y_test = train_test_split(df_X, df_y, test_size=0.33)

# Note convention that uppercase X means multiple features and lowercase y means single label
```

Note with hyperparameter tuning using test data to tune hyperparameters is not recommended because test information "leaks" to training making it overfit. Therefore you typically split data into train, validation and test. Validation is used to tune hyperparameters and test is used to evaluate final model. But this would mean that pretty big portion of your data is not used for training (eg. 20% as test and 20% as validation) so often validation data is based on rolling (K-folding) with cross-valadation (see more in section on training).