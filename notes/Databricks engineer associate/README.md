# Notes for Databricks Data Engineer Associate certification

## Data ingestion from file

### Standard methods

Access files directly

```sql
SELECT * FROM json.`path/001.json`
```

Create table/view AS

```sql
CREATE OR REPLACE TEMP VIEW events_temp_view
SELECT * FROM json.`path/001.json`
```

Previous solution do not support options (delimiters etc.). 
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

### COPY INTO
This is original method to get idempotency and re-triable solution. Every time you run COPY INTO already loaded files are skipped.

### Autoloader (stream)
Autoloader is newest solution that is better optimized (milions of files), can use cloud triggers (directory listings vs. file notification mode) and can evolve schema:
- addNewColumns (default) - stream fails, new columns are added to schema, existing columns are not changed -> stream is restarted and then succeed
- rescue - stream goes on and all new columns are recorded in special "rescued" column
- failOnNewColumns - stream fails and do not update schema, manual intervention is required
- none - stream goes on and just ignores new columns

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

## Ingesting SQL

```sql
CREATE TEMPORARY VIEW employees_table_vw
USING JDBC
OPTIONS (
  url "<jdbc_url>",
  dbtable "<table_name>",
  user '<username>',
  password '<password>'
)
```

```python
employees_table = (spark.read
  .format("jdbc")
  .option("url", "<jdbc_url>")
  .option("dbtable", "<table_name>")
  .option("user", "<username>")
  .option("password", "<password>")
  .load()
)
```


## Full pipeline - traditional streaming
Start reading raw data with autoloader as stream

```python
(spark.readStream
    .format("cloudFiles")
    .option("cloudFiles.format", "json")
    .option("cloudFiles.schemaHints", "time DOUBLE")
    .option("cloudFiles.schemaLocation", f"{DA.paths.checkpoints}/bronze")
    .load(DA.paths.data_landing_location)
    .createOrReplaceTempView("recordings_raw_temp"))
```

Use SQL commands to enrich raw data by adding filename a ingestion time.

```sql
CREATE OR REPLACE TEMPORARY VIEW recordings_bronze_temp AS (
  SELECT *, current_timestamp() receipt_time, input_file_name() source_file
  FROM recordings_raw_temp
)
```

Now store stream in proper table in bronze tier

```python
(spark.table("recordings_bronze_temp")
      .writeStream
      .format("delta")
      .option("checkpointLocation", f"{DA.paths.checkpoints}/bronze")
      .outputMode("append")
      .table("bronze"))
```

Continue to silver tier by streaming bronze table, aggregate/enrich and store in silver.

```python
(spark.readStream
  .table("bronze")
  .createOrReplaceTempView("bronze_tmp"))
```

```sql
CREATE OR REPLACE TEMPORARY VIEW recordings_w_pii AS (
  SELECT device_id, a.mrn, b.name, cast(from_unixtime(time, 'yyyy-MM-dd HH:mm:ss') AS timestamp) time, heartrate
  FROM bronze_tmp a
  INNER JOIN pii b
  ON a.mrn = b.mrn
  WHERE heartrate > 0)
```

```python
(spark.table("recordings_w_pii")
      .writeStream
      .format("delta")
      .option("checkpointLocation", f"{DA.paths.checkpoints}/recordings_enriched")
      .outputMode("append")
      .table("recordings_enriched"))
```

Triggers
- processingTime='10 seconds' (repeat every ...)
- once=True (process all new data in single batch)
- availableNow=True (process all new data in multiple batches)

## Full pipeline - delta live tables
Integrated solution that manages its own cluster, error handling, you can put targets for data quality and actions (report aka nothing, drop, fail with CONSTRAINT .. EXPECT .. ON VIOLATION)

### Ingest to bronze

Autoloader of raw data

```sql
CREATE OR REFRESH STREAMING LIVE TABLE sales_orders_raw
AS SELECT * FROM cloud_files("${datasets_path}/retail-org/sales_orders", "json", map("cloudFiles.inferColumnTypes", "true"))
```

Or with Python

```python
@dlt.view
def taxi_raw():
  return spark.read
    .format("json")
    .load("/databricks-datasets/nyctaxi/sample/json/")
```

Here with explicit schema (otherwise JSON always maps to strings)

```sql
CREATE OR REFRESH STREAMING LIVE TABLE wiki_raw
AS SELECT *
  FROM cloud_files(
    "/databricks-datasets/wikipedia-datasets/data-001/en_wikipedia/articles-only-parquet",
    "parquet",
    map("schema", "title STRING, id INT, revisionId INT, revisionTimestamp TIMESTAMP, revisionUsername STRING, revisionUsernameId INT, text STRING")
  )
```

```python
@dlt.table
def wiki_raw():
  return (
    spark.readStream.format("cloudFiles")
      .schema("title STRING, id INT, revisionId INT, revisionTimestamp TIMESTAMP, revisionUsername STRING, revisionUsernameId INT, text STRING")
      .option("cloudFiles.format", "parquet")
      .load("/databricks-datasets/wikipedia-datasets/data-001/en_wikipedia/articles-only-parquet")
  )
```

Here with Python to ingest from Kafka.

```python
import dlt
from pyspark.sql.functions import *
from pyspark.sql.types import *

@dlt.table
def stream_pageviews():
    connection = 'kafkashaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="Endpoint=sb:/myname.servicebus.windows.net/;SharedAccessKeyName=pageviewsReceiver;SharedAccessKey=mykey;'

    kafka_options = {
     "kafka.bootstrap.servers": "${var.eventhub_namespace_name}.servicebus.windows.net:9093",
     "kafka.sasl.mechanism": "PLAIN",
     "kafka.security.protocol": "SASL_SSL",
     "kafka.request.timeout.ms": "60000",
     "kafka.session.timeout.ms": "30000",
     "startingOffsets": "earliest",
     "kafka.sasl.jaas.config": connection,
     "subscribe": "pageviews",
      }
    return spark.readStream.format("kafka").options(**kafka_options).load()
```

### Processing to silver

Clean-up stream in silver - note we are creating STREAMING LIVE TABLE my_silver_table ... FROM STREAM(LIVE.my_bronze_table) so both input and result is stream.

```sql
CREATE OR REFRESH STREAMING LIVE TABLE sales_orders_cleaned(
  CONSTRAINT valid_order_number EXPECT (order_number IS NOT NULL) ON VIOLATION DROP ROW
)
COMMENT "The cleaned sales orders with valid order_number(s)."
AS
  SELECT f.customer_id, f.customer_name, f.number_of_line_items, 
         timestamp(from_unixtime((cast(f.order_datetime as long)))) as order_datetime, 
         date(from_unixtime((cast(f.order_datetime as long)))) as order_date, 
         f.order_number, f.ordered_products, c.state, c.city, c.lon, c.lat, c.units_purchased, c.loyalty_segment
  FROM STREAM(LIVE.sales_orders_raw) f
  LEFT JOIN LIVE.customers c
    ON c.customer_id = f.customer_id
    AND c.customer_name = f.customer_name
```

Or with Python

```python
@dlt.table
def streaming_silver():
  # Since we read the bronze table as a stream, this silver table is also
  # updated incrementally.
  return dlt.read_stream("streaming_bronze").where(...)
```

### Processing to gold

Aggregate to gold - note we are using LIVE TABLE ... FROM LIVE.my_silver_table this time so result is not streaming.

```sql
CREATE OR REFRESH LIVE TABLE sales_order_in_la
COMMENT "Sales orders in LA."
AS
  SELECT city, order_date, customer_id, customer_name, ordered_products_explode.curr, 
         sum(ordered_products_explode.price) as sales, 
         sum(ordered_products_explode.qty) as quantity, 
         count(ordered_products_explode.id) as product_count
  FROM (SELECT city, order_date, customer_id, customer_name, explode(ordered_products) as ordered_products_explode
        FROM LIVE.sales_orders_cleaned 
        WHERE city = 'Los Angeles')
  GROUP BY order_date, city, customer_id, customer_name, ordered_products_explode.curr
```

or with Python

```python
@dlt.table
def live_gold():
  # This table will be recomputed completely by reading the whole silver table
  # when it is updated.
  return dlt.read("streaming_silver").groupBy("user_id").count()
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

Select from old version

```sql
SELECT * FROM people10m TIMESTAMP AS OF '2018-10-18T22:15:12.013Z'
SELECT * FROM delta.`/tmp/delta/people10m` VERSION AS OF 123
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

## VIEWS
**Standard view** - long-lived tied to tables

```sql
CREATE VIEW view_delays_abq_lax AS
  SELECT * 
  FROM external_table 
  WHERE origin = 'ABQ' AND destination = 'LAX';

SELECT * FROM view_delays_abq_lax;
```

**Dynamic view** in Unity Catalog can be used for data masking - giving access to columns or rows based on user.

```sql
-- Column permissions
CREATE VIEW sales_redacted AS
SELECT
  user_id,
  CASE WHEN
    is_account_group_member('auditors') THEN email
    ELSE 'REDACTED'
  END AS email,
  country,
  product,
  total
FROM sales_raw

-- Row permissions
 CREATE VIEW sales_redacted AS
 SELECT
   user_id,
   country,
   product,
   total
 FROM sales_raw
 WHERE
   CASE
     WHEN is_account_group_member('managers') THEN TRUE
     ELSE total <= 1000000
   END;

-- Column data masking - extract domain only from email
CREATE VIEW sales_redacted AS
SELECT
  user_id,
  region,
  CASE
    WHEN is_account_group_member('auditors') THEN email
    ELSE regexp_extract(email, '^.*@(.*)$', 1)
  END
  FROM sales_raw
```

**Temp view** - tied to session and get lost after cluster restart, detaching from cluster, restarting Python kernel or from other notebooks.

```sql
CREATE TEMPORARY VIEW temp_view_delays_gt_120
AS SELECT * FROM external_table WHERE delay > 120 ORDER BY delay ASC;

SELECT * FROM temp_view_delays_gt_120;
```

**Global temp** view is visible in SHOW TABLES IN global_temp;  asn accesible by any notebooks as long cluster is running (note there might be security issues with this),

```sql
CREATE GLOBAL TEMPORARY VIEW global_temp_view_dist_gt_1000 
AS SELECT * FROM external_table WHERE distance > 1000;

SELECT * FROM global_temp.global_temp_view_dist_gt_1000;
```

## Pivot and higher order functions

### Parse JSON

```sql
SELECT mykey:device, mykey:geo:city 
```

Unpack and enforce schema (by reading it from example)

```sql
CREATE OR REPLACE TEMP VIEW parsed_events AS
  SELECT from_json(value, schema_of_json('{"device":"Linux","ecommerce":{"purchase_revenue_in_usd":1075.5,"total_item_quantity":1,"unique_items":1},"event_name":"finalize","event_previous_timestamp":1593879231210816,"event_timestamp":1593879335779563,"geo":{"city":"Houston","state":"TX"},"items":[{"coupon":"NEWBED10","item_id":"M_STAN_K","item_name":"Standard King Mattress","item_revenue_in_usd":1075.5,"price_in_usd":1195.0,"quantity":1}],"traffic_source":"email","user_first_touch_timestamp":1593454417513109,"user_id":"UA000000106116176"}')) AS json 
  FROM events_strings;

-- json column is now in struct type  
SELECT * FROM parsed_events

-- so we can eg. select all its fields separately
CREATE OR REPLACE TEMP VIEW new_events_final AS
  SELECT json.* 
  FROM parsed_events;
  
SELECT * FROM new_events_final
```

### Arrays

Explode array (make it multiple rows - denormalize)

```sql
SELECT user_id, event_timestamp, event_name, explode(items) AS item
FROM events
WHERE size(items) > 2
```

Other array functions:
- collect_set - get unique values for a field
- flatten - combine multiple arrays into single array
- array_distinct - remove duplicates from array

### Pivot
Aggregate values based on specific column values

```sql
CREATE OR REPLACE TABLE transactions AS

SELECT * FROM (
  SELECT
    email,
    order_id,
    transaction_timestamp,
    total_item_quantity,
    purchase_revenue_in_usd,
    unique_items,
    item.item_id AS item_id,
    item.quantity AS quantity
  FROM sales_enriched
) PIVOT (
  sum(quantity) FOR item_id in (
    'P_FOAM_K',
    'M_STAN_Q',
    'P_FOAM_S',
    'M_PREM_Q',
    'M_STAN_F',
    'M_STAN_T',
    'M_PREM_K',
    'M_PREM_F',
    'M_STAN_K',
    'M_PREM_T',
    'P_DOWN_S',
    'P_DOWN_K'
  )
);

SELECT * FROM transactions
```

### Higher order functions
- FILTER - filters array using lamda function
- EXIST - test whether statement is true for elements in array
- TRANSFORM - uses lamda function to transform array elements
- REDUCE - uses two lamda functions to come up with single value out of array

Examples

```sql
-- filter for sales of only king sized items
SELECT
  order_id,
  items,
  FILTER (items, i -> i.item_id LIKE "%K") AS king_items
FROM sales

-- get total revenue from king items per order
CREATE OR REPLACE TEMP VIEW king_item_revenues AS

SELECT
  order_id,
  king_items,
  TRANSFORM (
    king_items,
    k -> CAST(k.item_revenue_in_usd * 100 AS INT)
  ) AS item_revenues
FROM king_size_sales;
```