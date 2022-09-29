output "datalake_url" {
  value = azurerm_storage_account.main.primary_dfs_endpoint
}

output "datalake_name" {
  value = azurerm_storage_account.main.name
}

output "datalake_id" {
  value = azurerm_storage_account.main.id
}

output "eventhub_namespace_name" {
  value = azurerm_eventhub_namespace.main.name
}

output "eventhub_name_pageviews" {
  value = azurerm_eventhub.pageviews.name
}

output "eventhub_name_stars" {
  value = azurerm_eventhub.stars.name
}

output "eventhub_id_pageviews" {
  value = azurerm_eventhub.pageviews.id
}

output "eventhub_id_stars" {
  value = azurerm_eventhub.stars.id
}

output "sql_server_name" {
  value = azurerm_mssql_server.main.name
}