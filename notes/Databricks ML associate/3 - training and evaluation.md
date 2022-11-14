# Algorithms
## Linear regression
y = ax + b

- Predicts continuous values such as price
- Simple, fast to train, can be paralellized with MLLib in Spark
- Easy to interpret - coefficients (weights) of features tell about how model works
- Easy to tune (less worry about overfitting etc.)
- Not accurate for complex problems
- We need to convert categorical values to OHE (dummy variables) - not just indexer, because such numbers have no numerical meanings (if 1=cat, 2=dog, 3=mouse, it does not mean that dog is more than cat but less then mouse)

## Decision tree
- Tree of binary (true/false) decisions such as feature1 below or above median and so on
- Predicts categorical value such as buy/not-buy, cheap/expensive
- For regression problems, the predicted value is the mean of the training values in the leaf node
- First decision -> find feature that after split gives most information gain = best segregates responses (most blue on left, most red on right)
- Then repeat on next level -> find most information gain on split -> after you reach max depth or all responses are same
- We need to stop splitting at some point to avoid overfitting
- Easy to interpret
- Can capture non-linear problems
- Few hyperparameters to tune
- In MLLib we still need to convert all features to vector, but we will not use OHE (just indexer)

## Random forest
- Create multiple decision trees and average their predictions
- Key is to create trees that are different from each other (uncorrelated)
  - Bootstrap aggregation - each tree is trained on a random sample of the data
  - Feature randomness - each tree is trained on a random subset of features
- Hyperparameters to tune:
  - Number of trees (numTrees in MLLib, n_estimators in sklearn)
  - Max depth (maxDepth in MLLib, max_depth in sklearn)
  - Max bins (maxBins in MLLib, not in sklearn and it is not distributed)
  - Max features (featureSubsetStrategy in MLLib, max_features in sklearn)

# Training
First we need to declare model, in this example LiearRegression, where we need to specify features and label.

```python
lr = LinearRegression(featuresCol="features", labelCol="price")
```

Then we can just run fit on it with vectorized DataFrame as input.

```python
lr_model = lr.fit(vec_train_df)
```

More often we will use rather pipeline which is list of transformations applied. Here we appy following set of operations:
1. String index is converting categorical columns to index numbers (1 = cat, 2 = dog)
2. One Hot Encoder that converts this to dummy variables
3. Then we use VectorAssembler that will make our numerical and OHE features as dense vector
4. Final step is ML model itself
5. Once we have this Pipeline object defined, we can fit it on train_df

```python
from pyspark.ml import Pipeline

# Define pipeline
stages = [string_indexer, ohe_encoder, vec_assembler, lr]
pipeline = Pipeline(stages=stages)

# Train
pipeline_model = pipeline.fit(train_df)
```

# Hyperparameter tuning

## ParamGridBuilder
When there are a lot of hyperparameters we can tune, we can use ParamGrid to provide different values to try. Let's try maxDepth 2 or 5 and numTrees 5 or 10.

```python
from pyspark.ml.tuning import ParamGridBuilder

param_grid = (ParamGridBuilder()
              .addGrid(rf.maxDepth, [2, 5])
              .addGrid(rf.numTrees, [5, 10])
              .build())
```

## Cross validation
Tuning hyperparameters by validating against test dataset would leak information from test dataset to training. To avoid this we can use cross validation. We split our training dataset into k folds and then we train k models, each time using different fold as validation dataset and rest as training dataset. Then we average the results. This way we can tune hyperparameters and still have clean testing dataset to evaluate overall model performance.

What we do:
- Create steps in pipeline such as string indexers, vector assempler, model algorith
- Create evaluator
- Create param grid
- Create cross validator
- Create pipeline out of those
- Train the model

```python
from pyspark.ml.tuning import CrossValidator
cv = CrossValidator(estimator=rf, evaluator=evaluator, estimatorParamMaps=param_grid, numFolds=3, seed=42)
```

# Model evaluation

## Common metrics
- rmse (regression) - root mean squared error -> how far are predictions from actual values, lower is better
- r2 (regression) - r-squared -> how much of variance in data is explained by model, higher is better
- areaUnderROC (binary classification)
  - How well model can separate positive and negative examples, higher is better
  - Based on classification threshold plots following two numbers to create ROC curve
    - True Positive Rate (=recall) -> TP / (TP + FN)
    - False Positive Rate -> FP / (FP + TN)
  - Area under curve (AUC) is 0.5 if model is random, 1.0 if perfect
- accuracy (classicifation)
  - How many examples were classified correctly (TP + TN) / (TP + TN + FP + FN)
  - number alone does not tell anything -> for data samples with 99% blue and 1% green, accuracy of 99% is very bad (the same as model that always predicts blue)
- precission (classicifation)
  - What proportion of positive identifications was actually correct? TP / (TP + FP)
  - maximize for costly high-risk treatment (better to have as little false positives as possible = killing healthy person with high-risk unnecessary treatment)
- recall (classicifation)
  - What proportion of actual positives was identified correctly? TP / (TP + FN)
  - maximize for cheeap harmless treatment (better to have false positive = harmless treatment than false negative = death of unidentified patient)


## Linear Regression - get coefficients and intercept
Get resulting coefficients ("slope" of feature, importance) and intercept ("shift" of line).

```python
m = lr_model.coefficients[0]
b = lr_model.intercept

print(f"y = {m:.2f}x + {b:.2f}")
```

## Evaluate regression model
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

## Evaluate classification model
We can use BinaryClassificationEvaluator or MulticlassClassificationEvaluator

```python
from pyspark.ml.evaluation import BinaryClassificationEvaluator, MulticlassClassificationEvaluator
evaluator = BinaryClassificationEvaluator(labelCol="priceClass", rawPredictionCol="rawPrediction", metricName="areaUnderROC")
```

## Cross Validation

------
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