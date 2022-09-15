output "databricks_singlenode_cluster_id" {
  value = databricks_cluster.user_cluster.id
}

output "databricks_df_access_id" {
  value = azurerm_user_assigned_identity.databricks_df_access.id
}

output "databricks_etl_cluster_id" {
  value = databricks_cluster.etl_cluster.id
}

output "databricks_resource_id" {
  value = azurerm_databricks_workspace.main.id
}

output "databricks_domain_id" {
  value = azurerm_databricks_workspace.main.workspace_url
}