resource "databricks_metastore" "main" {
  name          = "mysilver"
  storage_root  = "abfss://silver@${var.storage_account_name}.dfs.core.windows.net"
  owner         = "account users"
  force_destroy = true

  lifecycle {
    ignore_changes = [delta_sharing_scope]
  }
}

resource "databricks_metastore_assignment" "main" {
  metastore_id = databricks_metastore.main.id
  workspace_id = azurerm_databricks_workspace.main.workspace_id
}

resource "databricks_catalog" "main" {
  metastore_id = databricks_metastore.main.id
  name         = "mycatalog"

  depends_on = [
    databricks_metastore_assignment.main
  ]
}

resource "databricks_grants" "df_identity_ACCESS" {
  catalog = databricks_catalog.main.name
  grant {
    principal  = "account users"
    privileges = ["ALL_PRIVILEGES", "USAGE", "CREATE"]
  }
}

resource "databricks_grants" "df_identity_access_schema" {
  schema = "${databricks_catalog.main.name}.${databricks_schema.main.name}"
  grant {
    principal  = "account users"
    privileges = ["ALL_PRIVILEGES", "USAGE", "CREATE"]
  }
}

resource "databricks_schema" "main" {
  catalog_name = databricks_catalog.main.id
  name         = "mydb"
}

resource "azapi_resource" "access_connector" {
  type                      = "Microsoft.Databricks/accessConnectors@2022-04-01-preview"
  name                      = var.name_prefix
  parent_id                 = var.resource_group_id
  location                  = var.location
  schema_validation_enabled = false

  identity {
    type = "SystemAssigned"
  }
  body = jsonencode({
    properties = {}
  })
}

resource "azurerm_role_assignment" "main" {
  scope                = data.azurerm_storage_account.data_lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.access_connector.identity[0].principal_id
}

resource "databricks_metastore_data_access" "main" {
  metastore_id = databricks_metastore.main.id
  name         = "dataaccess"

  azure_managed_identity {
    access_connector_id = azapi_resource.access_connector.id
  }

  is_default = true
}
