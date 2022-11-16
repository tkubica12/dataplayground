# Pandas
Very popular Python library for data manipulation and analysis. Unfortunatelly does not scale to Big Data so project Koalas was created to bring Pandas to Spark and leverage distributed computing. This project became park of PySpark 3.2 as in now native part of Spark.

```python
# Read Parquet file as Spark DataFrame
spark_df = spark.read.parquet(f"{DA.paths.datasets}/airbnb/sf-listings/sf-listings-2019-03-06-clean.parquet/")

# Read Parquet file as traditional Pandas DataFrae
import pandas as pd
pandas_df = pd.read_parquet(f"{DA.paths.datasets.replace('dbfs:/', '/dbfs/')}/airbnb/sf-listings/sf-listings-2019-03-06-clean.parquet/")

# Read Parquet file with Pandas API on Spark (formerly Koalas)
import pyspark.pandas as ps
df = ps.read_parquet(f"{DA.paths.datasets}/airbnb/sf-listings/sf-listings-2019-03-06-clean.parquet/")

# Convert Spark DataFram to Pandas API on Spark DataFrame (two options)
df = ps.DataFrame(spark_df)
df = spark_df.to_pandas_on_spark()

# Convert Pandas API on Spark DataFrame to Spark DataFrame
df.to_spark()

# Example - count by group Spark vs. Pandas API on Spark
spark_df.groupby("property_type").count().orderBy("count", ascending=False)
df["property_type"].value_counts()

# With Spark API you can use popular visualisation libraries like Matplotlib
df.plot(kind="hist", x="bedrooms", y="price", bins=200)

# Using Pandas SQL on Pandas API on Spark DataFrame
ps.sql("SELECT distinct(property_type) FROM {df}", df=df)
```

Most training examples in exam are using MLLib (Spark ML) which is distributed, but for small problems we can use sklearn (will run on driver). Spark 3.0 is adding features to accelerate some of that (we discussed previously how Hyperopt can be used to distribute hyperparametr tuning jobs of sklearn accross cluster). Eg. Pandas can be loaded as Pandas UDF that uses Apache Arrow to efficiently pass data (100x faster than row-at-time Python UDFs). Also supports iterator so it can be efficient in batches. Recently support was added to call Pandas function API directly on PySpark DataFrame.

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
