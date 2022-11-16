
# DecisionTreeRegressor

```python
# Create features vector
from pyspark.ml.feature import StringIndexer

categorical_cols = [field for (field, dataType) in train_df.dtypes if dataType == "string"]
index_output_cols = [x + "Index" for x in categorical_cols]

string_indexer = StringIndexer(inputCols=categorical_cols, outputCols=index_output_cols, handleInvalid="skip")

from pyspark.ml.feature import VectorAssembler

numeric_cols = [field for (field, dataType) in train_df.dtypes if ((dataType == "double") & (field != "price"))]

assembler_inputs = index_output_cols + numeric_cols
vec_assembler = VectorAssembler(inputCols=assembler_inputs, outputCol="features")

# Create decision tree model
from pyspark.ml.regression import DecisionTreeRegressor

dt = DecisionTreeRegressor(labelCol="price")

# Combine stages into pipeline
stages = [string_indexer, vec_assembler, dt]
pipeline = Pipeline(stages=stages)

# Train model
dt.setMaxBins(40)
pipeline_model = pipeline.fit(train_df)

# Display graphical representation of tree
dt_model = pipeline_model.stages[-1]
display(dt_model)

# Display feature importance (by index)
dt_model.featureImportances 

# Display feature importance more radable (by name)
import pandas as pd

features_df = pd.DataFrame(list(zip(vec_assembler.getInputCols(), dt_model.featureImportances)), columns=["feature", "importance"])
features_df

```
