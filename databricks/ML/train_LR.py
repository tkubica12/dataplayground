# Databricks notebook source
# MAGIC %md
# MAGIC # Linear Regression model
# MAGIC Predict order value based on orders and users features (eg. dayofweek, timeofweek, month of purchase, sex, administrative unit users lives in, vip status)

# COMMAND ----------

# MAGIC %md
# MAGIC Get orders from Feature Store

# COMMAND ----------

from databricks import feature_store

fs = feature_store.FeatureStoreClient()

df = fs.read_table(
  name='hive_metastore.features.orders',
)

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC Lookup users

# COMMAND ----------

from databricks.feature_store import FeatureLookup

feature_lookups = [
    FeatureLookup(
      table_name = 'hive_metastore.features.users',
      feature_names = [
            'total_orders_value', 
            'is_vip',
            'is_child',
            'is_teenager',
            'is_adult',
            'is_woman',
            'administrative_unit_Jihocesky',
            'administrative_unit_Jihomoravsky',
            'administrative_unit_Karlovarsky',
            'administrative_unit_Kralovehradecky',
            'administrative_unit_Liberecky',
            'administrative_unit_Moravskoslezsky',
            'administrative_unit_Olomoucky',
            'administrative_unit_Pardubicky',
            'administrative_unit_Plzensky',
            'administrative_unit_Stredocesky',
            'administrative_unit_Ustecky',
            'administrative_unit_Vysocina',
            'administrative_unit_Zlinsky'
          ],
      lookup_key = 'user_id'
    )
  ]


training_set = fs.create_training_set(
  df=df,
  feature_lookups = feature_lookups,
  label = 'order_value',
 exclude_columns = ['customer_id', 'product_id']
)

df = training_set.load_df()

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC Train model

# COMMAND ----------

from pyspark.ml.feature import RFormula
from pyspark.ml.regression import LinearRegression
from pyspark.ml import Pipeline
from pyspark.ml.evaluation import RegressionEvaluator
import mlflow
import mlflow.spark

train_df, test_df = df.randomSplit(weights=[0.8,0.2], seed=42)

with mlflow.start_run(run_name="LR-Single-Feature") as run:
    r_formula = RFormula(formula="order_value ~ . - order_id - user_id")
    lr = LinearRegression(labelCol="order_value", featuresCol="features")

    pipeline = Pipeline(stages=[r_formula, lr])
    pipeline_model = pipeline.fit(train_df)

    # Log parameters
    mlflow.autolog()

    # # Log model
    # mlflow.spark.log_model(pipeline_model, "model", input_example=train_df.limit(5).toPandas()) 

    # Evaluate predictions
    pred_df = pipeline_model.transform(test_df)
    regression_evaluator = RegressionEvaluator(predictionCol="prediction", labelCol="order_value", metricName="rmse")
    rmse = regression_evaluator.evaluate(pred_df)

    # Log metrics
    mlflow.log_metric("rmse", rmse)

    # Log in Feature Store
    fs.log_model(
        pipeline_model,
        "model",
        flavor=mlflow.spark,
        training_set=training_set,
        registered_model_name="order_value"
    )

    # Get runid
    run_id = mlflow.active_run().info.run_id

# COMMAND ----------

# MAGIC %md
# MAGIC Register model

# COMMAND ----------

model_uri = f"runs:/{run_id}/model"
mlflow.register_model(model_uri=model_uri, name="order_value")

# COMMAND ----------


