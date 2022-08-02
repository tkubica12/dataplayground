# Data playground
This repo contains my data learning project.

## Data generation
First step is to generate data and related Azure objects:
- Azure Storage Data Lake gen2
- Azure Event Hub
- Data generators and streamers

See [datageneration](datageneration/datageneration.md) for more details.

TBD:
- Azure SQL with orders
- Data Factory to move data from SQL to Data Lake

## Data analysis
- Azure Databricks environment to process data and other demos (visualization, ML)
- PowerBI dashboard to visualize data (+ using Synapse serverless to read Delta from data lake)
- AzureML training model using data processed by Databricks
