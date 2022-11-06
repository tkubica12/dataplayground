# My study notes for Databricks engineer associate exam

## Data ingestion from file

Access files directly

```sql
SELECT * FROM json.`path/001.json`
```

Create table/view AS

```sql
CREATE OR REPLACE TEMP VIEW events_temp_view
SELECT * FROM json.`path/001.json`
```

Previous option do not support options (delimiters etc.). 
Use CREATE ... USING ... OPTIONS to get reference to data.
Then use CREATE...AS to copy data to delta table

```sql
CREATE TABLE sales_csv
  (order_id LONG, email STRING, transactions_timestamp LONG, total_item_quantity INTEGER, purchase_revenue_in_usd DOUBLE, unique_items INTEGER, items STRING)
USING CSV
OPTIONS (
  header = "true",
  delimiter = "|"
)
LOCATION "path/file.csv"

CREATE TABLE sales_delta AS
SELECT * FROM sales_csv
```

Better is to use autoloader which will basically stream data from storage finding new files that appear there.

```python
def autoload_to_table(data_source, source_format, table_name, checkpoint_directory):
    query = (spark.readStream
                  .format("cloudFiles")
                  .option("cloudFiles.format", source_format)
                  .option("cloudFiles.schemaLocation", checkpoint_directory)
                  .load(data_source)
                  .writeStream
                  .option("checkpointLocation", checkpoint_directory)
                  .option("mergeSchema", "true")
                  .table(table_name))
    return query

query = autoload_to_table(data_source = f"{DA.paths.working_dir}/tracker",
                          source_format = "json",
                          table_name = "target_table",
                          checkpoint_directory = f"{DA.paths.checkpoints}/target_table")
```

## Delta tables operations
Clone table

```sql
CREATE OR REPLACE TABLE my_full_clone
DEEP CLONE my_source_table

CREATE OR REPLACE TABLE my_snapshot_reference_clone
SHALLOW CLONE my_source_table
```

Compact table (make files be optimal size)

```sql
OPTIMIZE my_table
```

Compact table and rearrange physical layout to accelerate queries to specific columns.

```sql
OPTIMIZE my_table
ZORDER BY my_id_column
```

Get transation history

```sql
DESCRIBE HISTORY my_table
```

Revert to previous point in time

```sql
RESTORE TABLE my_table TO VERSION AS OF 8 
```

Cleanup unused files

```sql
VACUUM my_table RETAIN 730 HOURS
```

Replacing table "in place" - will be new transaction, so stored in history

```sql
CREATE OR REPLACE TABLE events AS
SELECT * FROM parquet.`${da.paths.datasets}/ecommerce/raw/events-historical`
```

To replace table "in place", but only when data schema is identical.

```sql
INSERT OVERWRITE sales
SELECT * FROM parquet.`${da.paths.datasets}/ecommerce/raw/sales-historical/`
```

Append rows to table

```sql
INSERT INTO sales
SELECT * FROM parquet.`${da.paths.datasets}/ecommerce/raw/sales-30m`
```

Merge new data to existing table

```sql
CREATE OR REPLACE TEMP VIEW users_update AS 
SELECT *, current_timestamp() AS updated 
FROM parquet.`${da.paths.datasets}/ecommerce/raw/users-30m`

--Insert all new based on user_id and merge email information if not present in original
MERGE INTO users a
USING users_update b
ON a.user_id = b.user_id
WHEN MATCHED AND a.email IS NULL AND b.email IS NOT NULL THEN
  UPDATE SET email = b.email, updated = b.updated
WHEN NOT MATCHED THEN INSERT *
```

## Pivot and higher order functions
pivot, filter, exists, transform, reduce


COPY INTO sales


DROP TABLE IF EXISTS users_jdbc;

CREATE TABLE users_jdbc
USING JDBC
OPTIONS (
  url = "jdbc:sqlite:${DA.paths.ecommerce_db}",
  dbtable = "users"
)