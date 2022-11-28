# Databricks notebook source
storage_account_name = dbutils.secrets.get(scope="azure", key="storage_account_name")
eventhub_namespace_name = dbutils.secrets.get(scope="azure", key="eventhub_namespace_name")
eventhub_pages_key = dbutils.secrets.get(scope="azure", key="eventhub_pages_key")
eventhub_stars_key = dbutils.secrets.get(scope="azure", key="eventhub_stars_key")

import dlt
from pyspark.sql.functions import *
from pyspark.sql.types import *

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

