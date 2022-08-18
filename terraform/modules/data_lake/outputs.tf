output "datalake_url" {
  value = azurerm_storage_account.main.primary_dfs_endpoint
}

output "datalake_name" {
  value = azurerm_storage_account.main.name
}

output "datalake_id" {
  value = azurerm_storage_account.main.id
}

output "storage-writer_id" {
  value = azurerm_user_assigned_identity.storage-writer.id
}

output "eventhub_namespace_name" {
  value = azurerm_eventhub_namespace.main.name
}

output "eventhub_name" {
  value = azurerm_eventhub.pageviews.name
}