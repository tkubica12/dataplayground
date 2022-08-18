resource "azurerm_eventhub_namespace" "main" {
  name                = var.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  capacity            = 1
}

resource "azurerm_eventhub" "pageviews" {
  name                = "pageviews"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  partition_count     = 2
  message_retention   = 1

  capture_description {
    enabled = true
    encoding = "Avro"
    interval_in_seconds = 60
    destination {
      storage_account_id = azurerm_storage_account.main.id
      blob_container_name = azurerm_storage_container.bronze.name
      name = "EventHubArchive.AzureBlockBlob"
      archive_name_format = "pageviews_from_capture/{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
    }
  }
}

resource "azurerm_eventhub_authorization_rule" "pageviewsSender" {
  name                = "pageviewsSender"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  eventhub_name       = azurerm_eventhub.pageviews.name
  listen              = false
  send                = true
  manage              = false
}

