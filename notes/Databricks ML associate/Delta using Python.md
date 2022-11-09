# Delta in Python

```python
# Read Parquet from file
my_df = spark.read.format("parquet").load(file_path)

# Read CSV from file
my_df = spark.read.csv(file_path, header="true", inferSchema="true", multiLine="true", escape='"')

# Directly write df as Delta files
my_df.write.format("delta").mode("overwrite").save(directory_path)

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

