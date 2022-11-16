- [Preparing features](#preparing-features)
  - [Vector](#vector)
  - [Categorical features](#categorical-features)
  - [Automation with RFormula](#automation-with-rformula)
- [Feature Store](#feature-store)

# Preparing features

## Vector
Spark expects vectors as input. We can use VectorAssembler to convert numerical features to vector.

```python
from pyspark.ml.feature import VectorAssembler

# Create vector of features
vec_assembler = VectorAssembler(inputCols=["bedrooms"], outputCol="features")

# Apply vector assembler to training data and create features column
vec_train_df = vec_assembler.transform(train_df)
```

## Categorical features
For categorical feature we need to creat dummy variables (One Hot Encoding). This is two step process in Spark.

```python
from pyspark.ml.feature import OneHotEncoder, StringIndexer

# Get columns of type string
categorical_cols = [field for (field, dataType) in train_df.dtypes if dataType == "string"]

# Create name for categorical columns - one for index, one for OHE
index_output_cols = [x + "Index" for x in categorical_cols]
ohe_output_cols = [x + "OHE" for x in categorical_cols]

# Assign index to each category
string_indexer = StringIndexer(inputCols=categorical_cols, outputCols=index_output_cols, handleInvalid="skip")

# Convert category index to binary vector (dummy variables)
ohe_encoder = OneHotEncoder(inputCols=index_output_cols, outputCols=ohe_output_cols)

# Create vector of features (numerical + categorical)
from pyspark.ml.feature import VectorAssembler

numeric_cols = [field for (field, dataType) in train_df.dtypes if ((dataType == "double") & (field != "price"))]
assembler_inputs = ohe_output_cols + numeric_cols
vec_assembler = VectorAssembler(inputCols=assembler_inputs, outputCol="features")
```

## Automation with RFormula
Another approach is to automate this with RFormula by providing columns and let system automatically deal with numerical and cathegorical features. Than you will just use RFormula in pipeline instead of manually created VectorAssembler.

```python
# We need string "label_column ~ feature1 + feature2 + feature 3"
formula = "price ~ " + " + ".join(train_df.drop("price").columns)

# Get RFormula
r_formula = RFormula(formula="log_price ~ . - price")  # predict log_price based on all features except price
r_formula = RFormula(formula="price ~ f1 + f2")  # predict log_price based on features f1 and f2
```

# Feature Store
Centralized reposity of features to enable sharing and discovery across organization. 
- For model you might do some transformation on feature (eg. logarithm, normalization, unit conversion, parsing) and you do it with Spark on top of RAW JSON files via Delta Tables in Silver tier. But then application is using this model for real-time inferencing from their application code. How to ensure both transformations are consistent? How can application team discover what data model expects?
- As preparing features is significant portion of data science work it is import to not repeat yourself. One data source might be used for multiple teams and models and sharing already prepared features saves time.
- Feature transformations might evolve over time and you might need to look on previous versions.
- You will get lineage - information what notebooks, jobs, models and endpoints are using specific feature.
- Feature Store is kind of analogy to GOLD tier in data lake architecture - data ready for consumption by "end users" (training and inferencing jobs)
- Why feature store in real-time inferencing? Application calling model has some fresh data (features) such as page use is currently on, product he is viewing etc. But model is trained on much more than that - user data (age, sex, location), historical data (products purchased per category, usual order size, usual order day of week) etc. Model does not contain this data after it is trained, you need to supply it. App also does not have it, but can look it up based on customer_id.
- Data to Feature Store can be streamed using Delta Live Tables eg. Kafka stream of events can regulary add records to feature store. You can than run batch inferencing every day eg. to send emails with discounts to identified customers. Weekly you can retrain the model using Feature Store and get new model version that will now better reflect changes in trends and behaviors happend over last week.


```python
# Imports
from pyspark.sql.functions import monotonically_increasing_id, lit, expr, rand
import uuid
from databricks import feature_store
from pyspark.sql.types import StringType, DoubleType
from databricks.feature_store import feature_table, FeatureLookup
import mlflow
import mlflow.sklearn
from mlflow.models.signature import infer_signature
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score

# Feature Store client
fs = feature_store.FeatureStoreClient()

# Select numeric features and exclude price column (label)
numeric_cols = [x.name for x in airbnb_df.schema.fields if (x.dataType == DoubleType()) and (x.name != "price")]
numeric_features_df = airbnb_df.select(["index"] + numeric_cols)
display(numeric_features_df)

# Store in feature store
fs.create_table(
    name=table_name,
    primary_keys=["index"],
    df=numeric_features_df,
    schema=numeric_features_df.schema,
    description="Numeric features of airbnb data"
)

# Or you can write to existing table
fs.write_table(
    name=table_name,
    df=numeric_features_df,
    mode="overwrite"
)

# Or merge new columns
fs.write_table(
    name=table_name,
    df=numeric_features_df,
    mode="merge"
)

# Read from feature store
df = fs.read_table(table_name)
```

You can see output in UI - Feature Store section in ML in Databricks. Or via API:

```python
fs.get_table(table_name).path_data_sources
fs.get_table(table_name).description
```

This how to use Feature Store

```python
# Lookup features (basically join of my inferencing table and features table on customer_id)
model_feature_lookups = [FeatureLookup(table_name=table_name, lookup_key="customer_id")]
training_set = fs.create_training_set(inference_data_df, model_feature_lookups, label="price", exclude_columns="customer_id")
training_pd = training_set.load_df().toPandas()

# MLFlow can log model with Feature Store
mlflow.sklearn.autolog(log_models=False)

def train_model(X_train, X_test, y_train, y_test, training_set, fs):
    ## fit and log model
    with mlflow.start_run() as run:

        rf = RandomForestRegressor(max_depth=3, n_estimators=20, random_state=42)
        rf.fit(X_train, y_train)
        y_pred = rf.predict(X_test)

        mlflow.log_metric("test_mse", mean_squared_error(y_test, y_pred))
        mlflow.log_metric("test_r2_score", r2_score(y_test, y_pred))

        fs.log_model(
            model=rf,
            artifact_path="feature-store-model",
            flavor=mlflow.sklearn,
            training_set=training_set,
            registered_model_name=f"feature_store_airbnb_{DA.cleaned_username}",
            input_example=X_train[:5],
            signature=infer_signature(X_train, y_train)
        )

train_model(X_train, X_test, y_train, y_test, training_set, fs)

# Batch inferencing
predictions_df = fs.score_batch(f"models:/feature_store_airbnb_{DA.cleaned_username}/1", batch_input_df, result_type="double")
```