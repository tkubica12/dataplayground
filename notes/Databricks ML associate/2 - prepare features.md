

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