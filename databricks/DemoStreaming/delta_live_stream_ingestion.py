# Databricks notebook source
storage_account_name = dbutils.secrets.get(scope="azure", key="storage_account_name")
eventhub_namespace_name = dbutils.secrets.get(scope="azure", key="eventhub_namespace_name")

import dlt
from pyspark.sql.functions import *
from pyspark.sql.types import *

@dlt.table
def stream_pageviews():
    connection = f'kafkashaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="Endpoint=sb://{demo_event_hub_namespace_name}.servicebus.windows.net/;SharedAccessKeyName=pageviewsReceiver;SharedAccessKey=XHgMIyQMARC07awDJtCmUCS77HgG5YN45+8bzMbXvnI=";'

    kafka_options = {
     "kafka.bootstrap.servers": "lnoldtxpaibl.servicebus.windows.net:9093",
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
    connection = 'kafkashaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="Endpoint=sb://lnoldtxpaibl.servicebus.windows.net/;SharedAccessKeyName=starsReceiver;SharedAccessKey=Dn6qJhqRl2RqRHzYPCwkV+g/0/qLOxAAJv9FdMJl7wA=";'

    kafka_options = {
     "kafka.bootstrap.servers": "lnoldtxpaibl.servicebus.windows.net:9093",
     "kafka.sasl.mechanism": "PLAIN",
     "kafka.security.protocol": "SASL_SSL",
     "kafka.request.timeout.ms": "60000",
     "kafka.session.timeout.ms": "30000",
     "startingOffsets": "earliest",
     "kafka.sasl.jaas.config": connection,
     "subscribe": "stars",
      }
    return spark.readStream.format("kafka").options(**kafka_options).load()

