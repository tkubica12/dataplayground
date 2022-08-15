// Orders table
resource "azurerm_data_factory_dataset_sql_server_table" "orders" {
  name                = "ordersTable"
  data_factory_id     = azurerm_data_factory.main.id
  linked_service_name = azurerm_data_factory_linked_service_azure_sql_database.sql.name
  table_name          = "dbo.orders"
}

// Items table
resource "azurerm_data_factory_dataset_sql_server_table" "items" {
  name                = "itemsTable"
  data_factory_id     = azurerm_data_factory.main.id
  linked_service_name = azurerm_data_factory_linked_service_azure_sql_database.sql.name
  table_name          = "dbo.items"
}

// Orders Parquet store in bronze tier
resource "azurerm_data_factory_custom_dataset" "orders" {
  name            = "ordersParquet"
  data_factory_id = azurerm_data_factory.main.id
  type            = "Parquet"

  linked_service {
    name = azurerm_data_factory_linked_custom_service.datalake.name
  }

  type_properties_json = <<JSON
{
    "location": {
        "type": "AzureBlobFSLocation",
        "fileName": "fromDataFactory",
        "folderPath": "orders",
        "fileSystem": "bronze"
    },
    "compressionCodec": "snappy"
}
JSON

  schema_json = <<JSON
[]
JSON
}

// Items Parquet store in bronze tier
resource "azurerm_data_factory_custom_dataset" "items" {
  name            = "itemsParquet"
  data_factory_id = azurerm_data_factory.main.id
  type            = "Parquet"

  linked_service {
    name = azurerm_data_factory_linked_custom_service.datalake.name
  }

  type_properties_json = <<JSON
{
    "location": {
        "type": "AzureBlobFSLocation",
        "fileName": "fromDataFactory",
        "folderPath": "items",
        "fileSystem": "bronze"
    },
    "compressionCodec": "snappy"
}
JSON

  schema_json = <<JSON
[]
JSON
}
