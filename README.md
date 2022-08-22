# Data playground
This repo contains my data learning project. In order to play with enough data I have developed containerized generators and streamers to have data stored in different ways or streamed. In next phase I will add steps to prepare and consolidate data followed by different types of analysis and visualizations.

**Whole playground is designed to be completely automated with no prior dependencies. By running single Terraform template everything should get deployed, generators, streamers and other software started as containers hosted in Azure and Databrics, Synapse or Data Factory configurations pushed using proper Terraform providers or via Git references.**

## Deployment
Go to terraform folder and run it. Note that generators are started as Azure Container Instances and might take few hours to complete. In main.tf when calling modules you can modify certain inputs such as ammount of data generated.

```bash
cd terraform
az login
terraform init
terraform apply -auto-approve
```

## Current architecture
```mermaid
graph LR;
    Users_generator -- JSON lines flat file --> Data_Lake_Bronze;
    Products_generator -- JSON file per product --> Data_Lake_Bronze;
    Orders_generator -- table referencing user ID and product ID --> SQL;
    Items_generator -- table referencing orders --> SQL;
    Pageviews_generator -- events --> Event_Hub;
    Stars_generator -- events --> Event_Hub;
    Event_Hub --> Stream_Analytics -- RAW data as Parquet --> Data_Lake_Bronze;
    Stream_Analytics -- Aggrerations --> Data_Lake_Silver;
    Stream_Analytics -- Correlations --> Data_Lake_Silver;
    Stream_Analytics -- Alerts --> Data_Lake_Silver;
    SQL --> Data_Factory -- Parquet --> Data_Lake_Bronze;
    Data_Lake_Bronze --> Databricks -- processing --> Data_Lake_Silver;
    Data_Factory -. Orchestration .-> Databricks;

    classDef generators fill:#9bd9e6,stroke:#333,stroke-width:2px;
    class Users_generator,Products_generator,Orders_generator,Items_generator,Page_views_generator generators;

    classDef generators fill:#9bd9e6,stroke:#333,stroke-width:2px;
    class Users_generator,Products_generator,Orders_generator,Items_generator,Pageviews_generator,Stars_generator generators;

    style Data_Lake_Bronze fill:#b45f06,stroke:#333,stroke-width:2px
    style Data_Lake_Silver fill:#eeeeee,stroke:#333,stroke-width:2px
    style Data_Lake_Gold fill:#f7b511,stroke:#333,stroke-width:2px
        
    classDef endstate fill:#d1e6a8,stroke:#333,stroke-width:2px;
    class Model_API,PowerBI,Real_time_detection endstate;
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

## Data preparation and movement
This part contains consolidation of data sources into bronze tier and potentialy some manipulations and preparation.

- Data Factory gets deployed by Terraform with
  - Linked services
    - Key Vault service authenticated via User Managed Identity
    - SQL service with secrets stored in Key Vault
    - Data Lake gen2 service authenticated via User Managed Identity
  - Datasets
    - order and items tables in SQL (source)
    - order and items as Parquet files in Data Lake gen2 (sink)
  - Pipelines
    - Copy operation triggered every hour from SQL tables to Data Lake followed by Databricks job to process orders, items, pageviews, products and users fro bronze tier to Delta tables in Silver tier
- Stream Analytics getting raw pageviews and stars stream to bronze tier as Parquet files
- Databricks processing orchestrated by Data Factory
  - Two clusters - single node and serverless
  - Notebook to get data from bronze tier and create Delta tables in silver tier
  - Data movement from SQL do bronze tier and coordinated run of Databricks notebook is orchestrated via Data Factory pipeline
  
## Data analysis
- Stream Analytics
  - Alert on high latency requests
  - Enriching pageviews data with customer information for high latency requests
  - Aggregating pageviews by HTTP method in 5 minutes window
  - TBD: alerting on VIP users access (by looking up vip.json)
  - TBD: correlating two streams alerting on pageviews of user who gave <3 stars withing 10 minutes period
- TBD: Structured Streaming using Azure Databricks (implement the same functionality as above using different tool)
- TBD: Azure Databricks advanced processing, visualization and ML
- TBD: PowerBI dashboard to visualize data (+ using Synapse or Databricks serverless to read Delta from data lake)
- TBD: AzureML training model using data processed by Databricks
