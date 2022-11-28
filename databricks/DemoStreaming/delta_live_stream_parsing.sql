-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Parse pageviews

-- COMMAND ----------

CREATE OR REFRESH STREAMING LIVE TABLE parsed_pageviews
AS SELECT timestamp,
  get_json_object(CAST(value AS string), '$.user_id') AS user_id,
  get_json_object(CAST(value AS string), '$.http_method') AS http_method,
  get_json_object(CAST(value AS string), '$.uri') AS uri,
  get_json_object(CAST(value AS string), '$.client_ip') AS client_ip,
  get_json_object(CAST(value AS string), '$.user_agent') AS user_agent, 
  get_json_object(CAST(value AS string), '$.latency') AS latency 
FROM STREAM(live.stream_pageviews)

-- COMMAND ----------

CREATE OR REFRESH STREAMING LIVE TABLE parsed_stars
AS SELECT timestamp,
  get_json_object(CAST(value AS string), '$.user_id') AS user_id,
  get_json_object(CAST(value AS string), '$.stars') AS stars
FROM STREAM(live.stream_stars)

-- COMMAND ----------



-- COMMAND ----------


