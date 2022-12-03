# MLflow
OSS platform to managed ML lifecycle
- Tracking - tracks parameters, versions, quality metrics, logs (many frameworks are out-of-the box ready for this including Scikit-learn, TensorFlow/Keras, PyTorch, Spark ML, etc.)
- Projects - package code, dependencies, and environment into a reproducible workflow
- Models - package models for deployment
- Registry - store, annotate, version, discover, and manage models including stage transitions (from dev to prod), approvals as part of CI/CD

## Tracking

This is how tracking is enabled - basically run training inside mlflow.start_run

```python
import mlflow
import mlflow.spark
from pyspark.ml.regression import LinearRegression
from pyspark.ml.feature import VectorAssembler
from pyspark.ml import Pipeline
from pyspark.ml.evaluation import RegressionEvaluator

with mlflow.start_run(run_name="LR-Single-Feature") as run:
    # Define pipeline
    vec_assembler = VectorAssembler(inputCols=["bedrooms"], outputCol="features")
    lr = LinearRegression(featuresCol="features", labelCol="price")
    pipeline = Pipeline(stages=[vec_assembler, lr])
    pipeline_model = pipeline.fit(train_df)

    # Log parameters
    mlflow.log_param("label", "price")
    mlflow.log_param("features", "bedrooms")

    # Log model
    mlflow.spark.log_model(pipeline_model, "model", input_example=train_df.limit(5).toPandas()) 

    # Evaluate predictions
    pred_df = pipeline_model.transform(test_df)
    regression_evaluator = RegressionEvaluator(predictionCol="prediction", labelCol="price", metricName="rmse")
    rmse = regression_evaluator.evaluate(pred_df)

    # Log metrics
    mlflow.log_metric("rmse", rmse)
```

We can even store things like histograms.

```python
# Log artifact
plt.clf()

log_train_df.toPandas().hist(column="log_price", bins=100)
fig = plt.gcf()
mlflow.log_figure(fig, f"{DA.username}_log_normal.png")
```

Reading results

```python
from mlflow.tracking import MlflowClient

client = MlflowClient()

# List all experiments
client.search_experiments()

# Get ID of first experiment
client.search_experiments()[0]._experiment_id

# List runs in experiment
display(client.search_runs(client.search_experiments()[0]._experiment_id))
```

Here is what _data is in run JSON

```json
{
    "_metric_objs": [
        {
            "_key": "r2",
            "_step": 0,
            "_timestamp": 1667984987083,
            "_value": 0.4753471891187425
        },
        {
            "_key": "rmse",
            "_step": 0,
            "_timestamp": 1667984986967,
            "_value": 129.36887774567586
        }
    ],
    "_metrics": {
        "r2": 0.4753471891187425,
        "rmse": 129.36887774567586
    },
    "_params": {
        "features": "all_features",
        "label": "log_price"
    },
    "_tags": {
        "mlflow.log-model.history": "[{\"artifact_path\":\"log-model\",\"saved_input_example_info\":{\"artifact_path\":\"input_example.json\",\"type\":\"dataframe\",\"pandas_orient\":\"split\"},\"flavors\":{\"spark\":{\"pyspark_version\":\"3.3.0\",\"model_data\":\"sparkml\",\"code\":null},\"python_function\":{\"loader_module\":\"mlflow.spark\",\"python_version\":\"3.9.5\",\"data\":\"sparkml\",\"env\":\"conda.yaml\"}},\"run_id\":\"5e094c6f40d34a4595b02d2f1a961c80\",\"model_uuid\":\"85a1b12823d44be98d3903b435bb87c9\",\"utc_time_created\":\"2022-11-09 09:09:26.635995\",\"mlflow_version\":\"1.29.0\",\"databricks_runtime\":\"11.3.x-cpu-ml-scala2.12\"}]",
        "mlflow.databricks.gitRepoRelativePath": "ML 04 - MLflow Tracking",
        "mlflow.databricks.cluster.libraries": "{\"installable\":[],\"redacted\":[]}",
        "mlflow.databricks.gitRepoUrl": "https://github.com/databricks-academy/scalable-machine-learning-with-apache-spark-english.git",
        "mlflow.runName": "LR-Log-Price",
        "mlflow.databricks.gitRepoReference": "published",
        "mlflow.databricks.notebook.commandID": "6161537495714120330_6413397212632805393_7e85125ae0144c17a036c7cdc7eebc97",
        "mlflow.databricks.gitRepoStatus": "unknown",
        "mlflow.databricks.notebookPath": "/Repos/admin@tkubica.biz/scalable-machine-learning-with-apache-spark-english/ML 04 - MLflow Tracking",
        "mlflow.databricks.notebookID": "728605906705672",
        "mlflow.databricks.gitRepoReferenceType": "branch",
        "mlflow.databricks.gitRepoCommit": "4ec26e16ee122ce932fc437b9aabedadec2159ef",
        "mlflow.databricks.cluster.id": "1104-061318-a0kb5tra",
        "mlflow.source.type": "NOTEBOOK",
        "mlflow.databricks.cluster.info": "{\"cluster_name\":\"admin's Cluster\",\"spark_version\":\"11.3.x-cpu-ml-scala2.12\",\"node_type_id\":\"Standard_DS3_v2\",\"driver_node_type_id\":\"Standard_DS3_v2\",\"autotermination_minutes\":120,\"disk_spec\":{},\"num_workers\":0}",
        "mlflow.source.name": "/Repos/admin@tkubica.biz/scalable-machine-learning-with-apache-spark-english/ML 04 - MLflow Tracking",
        "mlflow.user": "admin@tkubica.biz",
        "mlflow.databricks.workspaceURL": "adb-7053260012155386.6.azuredatabricks.net",
        "mlflow.databricks.gitRepoProvider": "gitHub",
        "mlflow.databricks.workspaceID": "7053260012155386",
        "mlflow.databricks.webappURL": "https://westeurope-c2.azuredatabricks.net"
    }
}
```

And here _info from run

```json
{
    "_artifact_uri": "dbfs:/databricks/mlflow-tracking/d271bca464724621a87b0d2f333d2e29/5e094c6f40d34a4595b02d2f1a961c80/artifacts",
    "_end_time": 1667984988213,
    "_experiment_id": "d271bca464724621a87b0d2f333d2e29",
    "_lifecycle_stage": "active",
    "_run_id": "5e094c6f40d34a4595b02d2f1a961c80",
    "_run_uuid": "5e094c6f40d34a4595b02d2f1a961c80",
    "_start_time": 1667984935284,
    "_status": "FINISHED",
    "_user_id": ""
}
```

Model is part of MLflow artifacts and can be loaded.

```python
# Load model
model_path = f"runs:/{run.info.run_id}/log-model"
loaded_model = mlflow.spark.load_model(model_path)

# Run prediction
display(loaded_model.transform(test_df))
```

## Registry
Enable auto-logging by
- Calling mlflow.autolog() before training your model
- Setting this up on workspace level form the admin console
- Enable on per library basis such as mlflow.sklearn.autolog() or mlflow.keras.autolog()

```python
import mlflow
import mlflow.sklearn
from mlflow.models.signature import infer_signature

import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split

df = pd.read_csv(f"{DA.paths.datasets}/airbnb/sf-listings/airbnb-cleaned-mlflow.csv".replace("dbfs:/", "/dbfs/"))
X_train, X_test, y_train, y_test = train_test_split(df.drop(["price"], axis=1), df[["price"]].values.ravel(), random_state=42)

with mlflow.start_run(run_name="LR Model") as run:
    mlflow.sklearn.autolog(log_input_examples=True, log_model_signatures=True, log_models=True)
    lr = LinearRegression()
    lr.fit(X_train, y_train)
    signature = infer_signature(X_train, lr.predict(X_train))
```

Register model

```python
model_details = mlflow.register_model(model_uri=model_uri, name=model_name)
```

Working with stored model in Python

```python
# Get model reference
from mlflow.tracking.client import MlflowClient

client = MlflowClient()
model_version_details = client.get_model_version(name=model_name, version=1)

model_version_details.status

# Add description
client.update_registered_model(
    name=model_details.name,
    description="This model forecasts Airbnb housing list prices based on various listing inputs."
)

# Add version specific description
client.update_model_version(
    name=model_details.name,
    version=model_details.version,
    description="This model version was built using OLS linear regression with sklearn."
)
```

Each model version can have Stage information
- None
- Staging
- Production
- Archived

```python
# Change stage of certain model version
client.transition_model_version_stage(
    name=model_details.name,
    version=model_details.version,
    stage="Production"
)

# Check model version stage
model_version_details = client.get_model_version(
    name=model_details.name,
    version=model_details.version
)
print(f"The current model stage is: '{model_version_details.current_stage}'")
```

Load and use model

```python
import mlflow.pyfunc

model_version_uri = f"models:/{model_name}/1"

print(f"Loading registered model version from URI: '{model_version_uri}'")
model_version_1 = mlflow.pyfunc.load_model(model_version_uri)

model_version_1.predict(X_test)
```

Train and log new version of model

```python
from sklearn.linear_model import Ridge

with mlflow.start_run(run_name="LR Ridge Model") as run:
    alpha = .9
    ridge_regression = Ridge(alpha=alpha)
    ridge_regression.fit(X_train, y_train)

    # Specify the `registered_model_name` parameter of the `mlflow.sklearn.log_model()`
    # function to register the model with the MLflow Model Registry. This automatically
    # creates a new model version

    mlflow.sklearn.log_model(
        sk_model=ridge_regression,
        artifact_path="sklearn-ridge-model",
        registered_model_name=model_name,
    )

    mlflow.log_params(ridge_regression.get_params())
    mlflow.log_metric("mse", mean_squared_error(y_test, ridge_regression.predict(X_test)))

# Make this model staging
client.transition_model_version_stage(
    name=model_details.name,
    version=2,
    stage="Staging"
)

# Get latest version of model
model_version_infos = client.search_model_versions(f"name = '{model_name}'")
new_model_version = max([model_version_info.version for model_version_info in model_version_infos])

# Move v2 to production
client.transition_model_version_stage(
    name=model_name,
    version=new_model_version,
    stage="Production", 
    archive_existing_versions=True # Archive existing model in production 
)
```

Note you cannot remove model if there are any versions in active stages (staging and production).


