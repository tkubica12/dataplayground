// Copy orders
resource "azurerm_data_factory_pipeline" "copy_orders" {
  name            = "copy_orders"
  data_factory_id = azurerm_data_factory.main.id
  activities_json = <<JSON
[
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
    }
]
  JSON
}

resource "azurerm_data_factory_trigger_schedule" "orders_every_hour" {
  name            = "orders_every_hour"
  data_factory_id = azurerm_data_factory.main.id
  pipeline_name   = azurerm_data_factory_pipeline.copy_orders.name

  interval  = 1
  frequency = "Hour"
}

// Copy items
resource "azurerm_data_factory_pipeline" "copy_items" {
  name            = "copy_items"
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
    }
]
  JSON
}

resource "azurerm_data_factory_trigger_schedule" "items_every_hour" {
  name            = "items_every_hour"
  data_factory_id = azurerm_data_factory.main.id
  pipeline_name   = azurerm_data_factory_pipeline.copy_items.name

  interval  = 1
  frequency = "Hour"
}
