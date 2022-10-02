# Data playground
This repo contains my data learning project. In order to play with enough data I have developed containerized generators and streamers to have data stored in different ways or streamed. In next phase I will add steps to prepare and consolidate data followed by different types of analysis and visualizations.

**Whole playground is designed to be completely automated with no prior dependencies. By running single Terraform template everything should get deployed, generators, streamers and other software started as containers hosted in Azure and Databrics, Synapse or Data Factory configurations pushed using proper Terraform providers or via Git references.**

Basic data playground is packaged as reusable module (data lake, generators, SQL database) on top of which two solutions are built and can be deployed separately:
- Databricks solution -> End goal is using Databricks for ETL, stream processing, analytics and visualization
- Microsoft solution -> End goal is using Synapse for ETL and analytics, Stream Analytics for streaming and PowerBI for visualization

## Deployment
Go to terraform folder and run it. Note that generators are started as Azure Container Instances and might take few hours to complete. In main.tf when calling modules you can modify certain inputs such as ammount of data generated.

```bash
cd terraform
cd databricks_solution   # or microsoft_solution
az login
terraform init
terraform apply -auto-approve
```

## Data generation
Data generation module deploys following resources together with containers responsible for data generation and streaming:
- Azure Storage Data Lake gen2
- Azure Event Hub
- Azure SQL
- Data generators and streamers

Data sources:
- Users (JSON lines single flat file) in Azure Storage Data Lake gen2
- Products (JSON file per product) in Azure Storage Data Lake gen2
- Page views (data stream) and stars (another stream) streamed via Azure Event Hub
- Orders (relational tables) stored as orders and items tables in Azure SQL

See [datageneration](datageneration/datageneration.md) for more details.

## Microsoft solution
- Synapse is deployed
- Stream Analytics getting raw pageviews and stars stream to bronze tier as Parquet files
- Data processed from bronze tier and Azure SQL into Delta Tables in silver tier using DataFlow and Pipeline
- BI table is generated into gold tier by aggregating data from all sources into Parquet files
- Simple PowerBI dashboard
- Stream Analytics enrichment scenarios (output as files to silver tier)
  - Alert on high latency requests
  - Enriching pageviews data with customer information for high latency requests
  - Aggregating pageviews by HTTP method in 5 minutes window
  - Alerting on VIP users access (by looking up vip.json)
  - Correlating two streams (pageviews of users who also gave star over last 15 minutes)

TBD:
- Automate silver-to-gold with increments
- Incorporate AzureML

## Databricks solution
- Workspace deployed with cluster definitions
- Unity Catalog using managed identity to access storage layer
- Using auto-loader to get data from bronze tier to managed Unity Catalog tables (users, vipusers and products)
- Usign job to ingest data from SQL (orders and items)
- BI table into gold tier (scheduled as job)
- Streaming scenario with Delta Live Tables
  - Processing raw Kafka events from Event Hub
  - Parsing stream (decode base64 and parse JSON)
  - Correlate two streams
  - Identiy high latency pageviews

TBD:
- Implement other streaming scenarios (waiting for DLT support for Unity Catalog)
- Redisign bronze-to-silver to use DLT (waiting for DLT support for Unity Catalog)
- Visualizations with Dashboard (waiting for better API documentation)
- Incorporate SQL persona, investigate serverless SQL warehouse
- Leverage AutoML in Databricks
