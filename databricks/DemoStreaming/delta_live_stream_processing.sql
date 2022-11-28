-- Databricks notebook source
-- MAGIC %md
-- MAGIC # High latency alert

-- COMMAND ----------

CREATE OR REFRESH STREAMING LIVE TABLE high_latency
AS SELECT *
FROM STREAM(live.parsed_pageviews)
WHERE latency > 4000

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Pageviews with stars correlation

-- COMMAND ----------

CREATE OR REFRESH STREAMING LIVE TABLE pageviews_stars_correlation
AS SELECT live.parsed_pageviews.user_id,
          live.parsed_pageviews.http_method,
          live.parsed_pageviews.uri,
          live.parsed_pageviews.client_ip,
          live.parsed_pageviews.user_agent,
          live.parsed_pageviews.latency,
          live.parsed_stars.stars
FROM STREAM(live.parsed_pageviews)
JOIN STREAM(live.parsed_stars)
  ON live.parsed_pageviews.user_id = live.parsed_stars.user_id
  AND DATEDIFF(MINUTE, live.parsed_pageviews.timestamp,live.parsed_stars.timestamp) BETWEEN 0 AND 15  

-- COMMAND ----------


