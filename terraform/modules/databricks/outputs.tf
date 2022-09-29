output "databricks_resource_id" {
  value = azurerm_databricks_workspace.main.id
}

output "databricks_domain_id" {
  value = azurerm_databricks_workspace.main.workspace_url
}
