# Get configuration parameters and secrets
storage_account_name = dbutils.secrets.get(scope="azure", key="storage_account_name")
eventhub_namespace_name = dbutils.secrets.get(scope="azure", key="eventhub_namespace_name")
eventhub_pages_key = dbutils.secrets.get(scope="azure", key="eventhub_pages_key")
eventhub_stars_key = dbutils.secrets.get(scope="azure", key="eventhub_stars_key")
azuresql_password = dbutils.secrets.get(scope="azure", key="azuresql")
sql_server_name = dbutils.secrets.get(scope="azure", key="sql_server_name")

# Imports
import dlt
from pyspark.sql.functions import *
from pyspark.sql.types import *

# Pageviews from Kafka
@dlt.table
def stream_pageviews():
    connection = f'kafkashaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="Endpoint=sb://{eventhub_namespace_name}.servicebus.windows.net/;SharedAccessKeyName=pageviewsReceiver;SharedAccessKey={eventhub_pages_key}";'

    kafka_options = {
     "kafka.bootstrap.servers": f"{eventhub_namespace_name}.servicebus.windows.net:9093",
     "kafka.sasl.mechanism": "PLAIN",
     "kafka.security.protocol": "SASL_SSL",
     "kafka.request.timeout.ms": "60000",
     "kafka.session.timeout.ms": "30000",
     "startingOffsets": "earliest",
     "kafka.sasl.jaas.config": connection,
     "subscribe": "pageviews",
      }
    return spark.readStream.format("kafka").options(**kafka_options).load()

# Stars from Kafka
@dlt.table
def stream_stars():
    connection = f'kafkashaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="Endpoint=sb://{eventhub_namespace_name}.servicebus.windows.net/;SharedAccessKeyName=starsReceiver;SharedAccessKey={eventhub_stars_key}";'

    kafka_options = {
     "kafka.bootstrap.servers": f"{eventhub_namespace_name}.servicebus.windows.net:9093",
     "kafka.sasl.mechanism": "PLAIN",
     "kafka.security.protocol": "SASL_SSL",
     "kafka.request.timeout.ms": "60000",
     "kafka.session.timeout.ms": "30000",
     "startingOffsets": "earliest",
     "kafka.sasl.jaas.config": connection,
     "subscribe": "stars",
      }
    return spark.readStream.format("kafka").options(**kafka_options).load()


# Users from Azure Storage
data_path_users = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/users/"
checkpoint_path_users = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/_checkpoint/users"

@dlt.table()
def stream_users():
  return (
    spark.readStream.format("cloudFiles")
     .option("cloudFiles.format", "json")
     .option("cloudFiles.schemaLocation", checkpoint_path_users)
     .load(data_path_users)
 )


data_path_vipusers = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/vipusers/"
checkpoint_path_vipusers = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/_checkpoint/vipusers"

# VIP Users from Azure Storage
@dlt.table()
def stream_vipusers():
  return (
    spark.readStream.format("cloudFiles")
     .option("cloudFiles.format", "json")
     .option("cloudFiles.schemaLocation", checkpoint_path_vipusers)
     .load(data_path_vipusers)
 )

# Products from Azure Storage
data_path_products = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/products/"
checkpoint_path_products = f"abfss://bronze@{storage_account_name}.dfs.core.windows.net/_checkpoint/products"

@dlt.table()
def stream_products():
  return (
    spark.readStream.format("cloudFiles")
     .option("cloudFiles.format", "json")
     .option("cloudFiles.schemaLocation", checkpoint_path_products)
     .load(data_path_products)
 )

# Orders and items from Azure SQL Database
url = f"jdbc:sqlserver://{sql_server_name}.database.windows.net:1433;database=orders"

@dlt.table()
def stream_orders():
  return (
    spark.read.format("jdbc")
     .option("url", url)
     .option("database", "orders")
     .option("dbtable", "orders")
     .option("user", "tomas")
     .option("password", azuresql_password)
     .load()
 )

@dlt.table()
def stream_items():
  return (
    spark.read.format("jdbc")
     .option("url", url)
     .option("database", "orders")
     .option("dbtable", "items")
     .option("user", "tomas")
     .option("password", azuresql_password)
     .load()
 )