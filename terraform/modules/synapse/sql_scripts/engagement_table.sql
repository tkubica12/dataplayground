IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'gold')
BEGIN
    CREATE DATABASE gold;
END

GO

USE gold;

GO

IF NOT EXISTS(SELECT * FROM sys.symmetric_keys WHERE name = 'gold')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'My-Superencryptionpassword@';
END

GO

IF NOT EXISTS(SELECT * FROM sys.database_scoped_credentials WHERE name = 'ManagedIdentity')
BEGIN
    CREATE DATABASE SCOPED CREDENTIAL ManagedIdentity 
    WITH IDENTITY = 'Managed Identity';
END

GO

IF NOT EXISTS(SELECT * FROM sys.external_data_sources WHERE name = 'gold')
BEGIN
    CREATE EXTERNAL DATA SOURCE gold
    WITH ( 
        LOCATION = 'https://vvmyhsmvumdn.dfs.core.windows.net/gold/',
        CREDENTIAL = ManagedIdentity
        )
END

GO

IF NOT EXISTS(SELECT * FROM sys.external_file_formats WHERE name = 'ParquetFormat')
BEGIN
    CREATE EXTERNAL FILE FORMAT ParquetFormat
    WITH
    (  
        FORMAT_TYPE = PARQUET,
        DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
    )
END

GO

IF NOT EXISTS(SELECT * FROM sys.external_tables WHERE name = 'engagements')
BEGIN
    CREATE EXTERNAL TABLE engagements 
    WITH (
        LOCATION = 'engagements/',
        DATA_SOURCE = gold,
        FILE_FORMAT = ParquetFormat
    )
    AS (
      SELECT users.id, 
            users.user_name, 
            users.city, 
            CASE WHEN vipusers.id >= 0 THEN 1 ELSE 0 END AS is_vip,
            COUNT(pageviews.user_id) AS pageviews,
            COUNT(aggregatedOrders.userId) AS orders,
            SUM(aggregatedOrders.orderValue) AS total_orders_value,
            AVG(aggregatedOrders.orderValue) AS avg_order_value,
            SUM(aggregatedOrders.itemsCount) AS total_items,
            AVG(stars.stars) AS avg_stars
      FROM OPENROWSET(
          BULK 'https://vvmyhsmvumdn.dfs.core.windows.net/silver/users/',
          FORMAT = 'delta') as users
      LEFT JOIN OPENROWSET(
          BULK 'https://vvmyhsmvumdn.dfs.core.windows.net/silver/pageviews/',
          FORMAT = 'delta') as pageviews ON users.id = pageviews.user_id
      LEFT JOIN OPENROWSET(
          BULK 'https://vvmyhsmvumdn.dfs.core.windows.net/silver/stars/',
          FORMAT = 'delta') as stars ON users.id = stars.user_id
      LEFT JOIN OPENROWSET(
          BULK 'https://vvmyhsmvumdn.dfs.core.windows.net/silver/vipusers/',
          FORMAT = 'delta') as vipusers ON users.id = vipusers.id
      LEFT JOIN (
          SELECT orders.userId, orders.orderValue, orders.orderId, COUNT(items.orderId) AS itemsCount
              FROM OPENROWSET(
              BULK 'https://vvmyhsmvumdn.dfs.core.windows.net/silver/orders/',
              FORMAT = 'delta') as orders
          LEFT JOIN OPENROWSET(
              BULK 'https://vvmyhsmvumdn.dfs.core.windows.net/silver/items/',
              FORMAT = 'delta') as items ON orders.orderId = items.orderId
          GROUP BY orders.userId, orders.orderValue, orders.orderId) AS aggregatedOrders ON users.id = aggregatedOrders.userId
      GROUP BY users.id, users.user_name, users.city, vipusers.id
    )
END

GO

-- USE master;
-- DROP DATABASE gold;

