# Basic preparation

```python
# Select just certain columns
my_df = raw_df.select(["beds","bed_type"])

# Parse price from string (remove $ and , and cast to double)
fixed_price_df = base_df.withColumn("price", translate(col("price"), "$,", "").cast("double"))

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
- Use techniques like ALS (Alternating Least Squares) which are designed to impute missing values

If you do ANY imputation techniques for categorical/numerical features, you MUST include an additional field specifying that field was imputed.

```python
from pyspark.ml.feature import Imputer

imputer = Imputer(strategy="median", inputCols=impute_cols, outputCols=impute_cols)

imputer_model = imputer.fit(doubles_df)
imputed_df = imputer_model.transform(doubles_df)
```