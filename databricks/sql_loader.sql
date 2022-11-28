-- Databricks notebook source
-- COMMAND ----------

-- MAGIC %python
-- MAGIC azuresql_password = dbutils.secrets.get(scope="azure", key="azuresql")
-- MAGIC storage_account_name = dbutils.secrets.get(scope="azure", key="storage_account_name")
-- MAGIC 
-- MAGIC command = f'''
-- MAGIC CREATE TABLE IF NOT EXISTS jdbc_orders
-- MAGIC USING org.apache.spark.sql.jdbc
-- MAGIC OPTIONS (
-- MAGIC   url "jdbc:sqlserver://{storage_account_name}.database.windows.net:1433;database=orders",
-- MAGIC   database "orders",
-- MAGIC   dbtable "orders",
-- MAGIC   user "tomas",
-- MAGIC   password "{azuresql_password}"
-- MAGIC )'''
-- MAGIC 
-- MAGIC spark.sql(command)

-- COMMAND ----------

CREATE OR REPLACE TABLE mycatalog.mydb.orders
AS SELECT * FROM jdbc_orders

-- COMMAND ----------

-- MAGIC %python
-- MAGIC azuresql_password = dbutils.secrets.get(scope="azure", key="azuresql")
-- MAGIC storage_account_name = dbutils.secrets.get(scope="azure", key="storage_account_name")
-- MAGIC 
-- MAGIC command = f'''
-- MAGIC CREATE TABLE IF NOT EXISTS jdbc_items
-- MAGIC USING org.apache.spark.sql.jdbc
-- MAGIC OPTIONS (
-- MAGIC   url "jdbc:sqlserver://{storage_account_name}.database.windows.net:1433;database=orders",
-- MAGIC   database "orders",
-- MAGIC   dbtable "items",
-- MAGIC   user "tomas",
-- MAGIC   password "{azuresql_password}"
-- MAGIC )'''
-- MAGIC 
-- MAGIC spark.sql(command)

-- COMMAND ----------

CREATE OR REPLACE TABLE mycatalog.mydb.items
AS SELECT * FROM jdbc_items
