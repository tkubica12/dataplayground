// Metastore
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

// Catalog
resource "databricks_catalog" "main" {
  metastore_id  = databricks_metastore.main.id
  name          = "mycatalog"
  force_destroy = true

  depends_on = [
    databricks_metastore_assignment.main
  ]
}

resource "databricks_grants" "df_identity_access" {
  catalog = databricks_catalog.main.name
  grant {
    principal  = "account users"
    privileges = ["USAGE", "CREATE"]
  }
}

resource "databricks_grants" "df_identity_access_schema" {
  schema = "${databricks_catalog.main.name}.${databricks_schema.main.name}"
  grant {
    principal  = "account users"
    privileges = ["USAGE", "CREATE"]
  }
}

// Schema (database)
resource "databricks_schema" "main" {
  catalog_name  = databricks_catalog.main.id
  name          = "mydb"
  force_destroy = true
}

// Storage access - connector
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

// Storage access - managed identity credentials (for direct access to raw data)
resource "databricks_storage_credential" "external_mi" {
  name = "mi_credential"
  azure_managed_identity {
    access_connector_id = azapi_resource.access_connector.id
  }
  depends_on = [
    databricks_metastore_assignment.main
  ]
}

resource "databricks_grants" "external_creds" {
  storage_credential = databricks_storage_credential.external_mi.id
  grant {
    principal  = "account users"
    privileges = ["READ_FILES"]
  }
}

// RBAC right to storage for managed identity
resource "azurerm_role_assignment" "main" {
  scope                = data.azurerm_storage_account.data_lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.access_connector.identity[0].principal_id
}

// Metastore to use managed identity access connector
resource "databricks_metastore_data_access" "main" {
  metastore_id = databricks_metastore.main.id
  name         = "dataaccess"

  azure_managed_identity {
    access_connector_id = azapi_resource.access_connector.id
  }

  is_default = true
}

