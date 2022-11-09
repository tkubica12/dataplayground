# Linear regression
Split data

```python
train_df, test_df = airbnb_df.randomSplit([.8, .2], seed=42)
```

Linear Regression estimator expects vector as input.

```python
from pyspark.ml.feature import VectorAssembler

# Create vector of features
vec_assembler = VectorAssembler(inputCols=["bedrooms"], outputCol="features")

# Apply vector assembler to training data and create features column
vec_train_df = vec_assembler.transform(train_df)
```

Train

```python
lr = LinearRegression(featuresCol="features", labelCol="price")
lr_model = lr.fit(vec_train_df)
```

Get resulting coefficients ("slope" of feature, importance) and intercept ("shift" of line).

```python
m = lr_model.coefficients[0]
b = lr_model.intercept

print(f"y = {m:.2f}x + {b:.2f}")
```

Get predictions for test data and evaluate model

```python
# Apply vector assembler to test data and create features column
vec_test_df = vec_assembler.transform(test_df)

# Get predictions
pred_df = lr_model.transform(vec_test_df)

# Show predictions
pred_df.select("bedrooms", "features", "price", "prediction").show()

# Calcualate root mean squared error and r-squared
from pyspark.ml.evaluation import RegressionEvaluator

regression_evaluator = RegressionEvaluator(predictionCol="prediction", labelCol="price", metricName="rmse")

rmse = regression_evaluator.evaluate(pred_df)
print(f"RMSE is {rmse}")

r2 = regression_evaluator.setMetricName("r2").evaluate(pred_df)
print(f"R2 is {r2}")
```

Creating dummy variables (one-hot encoding) for categorical features

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

# Create model
from pyspark.ml.regression import LinearRegression

lr = LinearRegression(labelCol="price", featuresCol="features")
```

To have flexibility to define transformations in any order and have single place where ordering is decided, we can use pipeline.

```python
from pyspark.ml import Pipeline

# Define pipeline
stages = [string_indexer, ohe_encoder, vec_assembler, lr]
pipeline = Pipeline(stages=stages)

# Train
pipeline_model = pipeline.fit(train_df)
```

Saving and loading model

```python
# Save model to storage
pipeline_model.write().overwrite().save(directory_path)

# Load model from storage
from pyspark.ml import PipelineModel
saved_pipeline_model = PipelineModel.load(directory_path)
```