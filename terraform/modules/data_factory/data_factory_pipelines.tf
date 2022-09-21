
resource "azurerm_data_factory_pipeline" "process_data" {
  name            = "process_data"
  data_factory_id = azurerm_data_factory.main.id
  activities_json = <<JSON
[
            {
                "name": "CopyItems",
                "type": "Copy",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "SqlServerSource",
                        "queryTimeout": "02:00:00",
                        "partitionOption": "None"
                    },
                    "sink": {
                        "type": "ParquetSink",
                        "storeSettings": {
                            "type": "AzureBlobFSWriteSettings"
                        },
                        "formatSettings": {
                            "type": "ParquetWriteSettings"
                        }
                    },
                    "enableStaging": false
                },
                "inputs": [
                    {
                        "referenceName": "itemsTable",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "itemsParquet",
                        "type": "DatasetReference"
                    }
                ]
            },
            {
                "name": "CopyOrders",
                "type": "Copy",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "SqlServerSource",
                        "queryTimeout": "02:00:00",
                        "partitionOption": "None"
                    },
                    "sink": {
                        "type": "ParquetSink",
                        "storeSettings": {
                            "type": "AzureBlobFSWriteSettings"
                        },
                        "formatSettings": {
                            "type": "ParquetWriteSettings"
                        }
                    },
                    "enableStaging": false
                },
                "inputs": [
                    {
                        "referenceName": "ordersTable",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ordersParquet",
                        "type": "DatasetReference"
                    }
                ]
            },
            {
                "name": "ProcessDataWithDatabricks",
                "type": "DatabricksNotebook",
                "dependsOn": [
                    {
                        "activity": "CopyOrders",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
                    {
                        "activity": "CopyItems",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "/Shared/CreateDeltaLake"
                },
                "linkedServiceName": {
                    "referenceName": "Databricks",
                    "type": "LinkedServiceReference"
                }
            }
        ]
JSON
  depends_on = [
    azurerm_data_factory_dataset_sql_server_table.items,
    azurerm_data_factory_dataset_sql_server_table.orders,
    azurerm_data_factory_custom_dataset.items,
    azurerm_data_factory_custom_dataset.orders,
    azurerm_data_factory_linked_custom_service.databricks,
    azurerm_data_factory_linked_service_azure_sql_database.sql,
    azurerm_data_factory_linked_custom_service.datalake,
  ]

}

// Run every few hours
resource "azurerm_data_factory_trigger_schedule" "trigger" {
  name            = "trigger"
  data_factory_id = azurerm_data_factory.main.id
  pipeline_name   = azurerm_data_factory_pipeline.process_data.name

  interval  = 30
  frequency = "Minute"
}

// Run when users are generated
resource "azurerm_data_factory_trigger_blob_event" "users" {
  name                = "users"
  data_factory_id     = azurerm_data_factory.main.id
  storage_account_id  = var.datalake_id
  events              = ["Microsoft.Storage.BlobCreated"]
  
  blob_path_begins_with = "/bronze/blobs/users/"
  ignore_empty_blobs  = true
  activated           = true

  pipeline {
    name = azurerm_data_factory_pipeline.process_data.name
  }
}

// Run when projects are generated
resource "azurerm_data_factory_trigger_blob_event" "projects" {
  name                = "projects"
  data_factory_id     = azurerm_data_factory.main.id
  storage_account_id  = var.datalake_id
  events              = ["Microsoft.Storage.BlobCreated"]
  
  blob_path_begins_with = "/bronze/blobs/projects/"
  ignore_empty_blobs  = true
  activated           = true

  pipeline {
    name = azurerm_data_factory_pipeline.process_data.name
  }
}
