// Metastore
resource "databricks_metastore" "main" {
  count = var.existing_metastore_id != "" ? 0 : 1
  name          = "mymetastore"
  storage_root  = "abfss://silver@${var.storage_account_name}.dfs.core.windows.net"
  owner         = "account users"
  force_destroy = true

  lifecycle {
    ignore_changes = [delta_sharing_scope]
  }
}

locals {
  metastore_id = var.existing_metastore_id != "" ? var.existing_metastore_id : databricks_metastore.main[0].id
}

resource "databricks_metastore_assignment" "main" {
  metastore_id = local.metastore_id
  workspace_id = azurerm_databricks_workspace.main.workspace_id
}

// Catalog
resource "databricks_catalog" "main" {
  metastore_id  = local.metastore_id
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
    privileges = ["USAGE", "CREATE", "CREATE_SCHEMA", "USE_CATALOG"]
  }
}

resource "databricks_grants" "df_identity_access_schema" {
  schema = "${databricks_catalog.main.name}.${databricks_schema.main.name}"
  grant {
    principal  = "account users"
    privileges = ["USAGE", "CREATE", "CREATE_FUNCTION", "CREATE_TABLE",  "USE_SCHEMA"] # "CREATE_VIEW",
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
  count = var.existing_metastore_id != "" ? 0 : 1
  metastore_id = local.metastore_id
  name         = "dataaccess"

  azure_managed_identity {
    access_connector_id = azapi_resource.access_connector.id
  }

  is_default = true
}

// Silver tier as external location
# resource "databricks_external_location" "silver" {
#   name            = "silver"
#   url             = "abfss://silver@${var.storage_account_name}.dfs.core.windows.net"
#   credential_name = databricks_storage_credential.external_mi.id

#   depends_on = [
#     databricks_metastore_assignment.main
#   ]
# }

# resource "databricks_grants" "silver" {
#   external_location = databricks_external_location.silver.id
#   grant {
#     principal  =  "account users"
#     privileges = ["CREATE_TABLE", "READ_FILES", "WRITE_FILES"]
#   }
# }

// Gold tier as external location
resource "databricks_external_location" "gold" {
  name            = "gold"
  url             = "abfss://gold@${var.storage_account_name}.dfs.core.windows.net"
  credential_name = databricks_storage_credential.external_mi.id
  skip_validation = true

  depends_on = [
    databricks_metastore_assignment.main
  ]
}

resource "databricks_grants" "gold" {
  external_location = databricks_external_location.gold.id
  grant {
    principal  = "account users"
    privileges = ["CREATE_TABLE", "CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }
}

// Bronze tier as external location
resource "databricks_external_location" "bronze" {
  name            = "bronze"
  url             = "abfss://bronze@${var.storage_account_name}.dfs.core.windows.net"
  credential_name = databricks_storage_credential.external_mi.id

  depends_on = [
    databricks_metastore_assignment.main
  ]
}

resource "databricks_grants" "bronze" {
  external_location = databricks_external_location.bronze.id
  grant {
    principal  = "account users"
    privileges = ["CREATE_TABLE", "CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }
}

// Engagements tabke
// NOTE: This is here because force delete of external location is not supported by Terraform
// so in order for destroy to work table needs to be managed by Terraform 
resource "databricks_table" "engagements" {
  name               = "engagements"
  catalog_name       = databricks_catalog.main.name
  schema_name        = databricks_schema.main.name
  table_type         = "EXTERNAL"
  storage_location   = "abfss://gold@${var.storage_account_name}.dfs.core.windows.net/engagements"
  data_source_format = "DELTA"

  depends_on = [
    databricks_external_location.gold
  ]

  column {
    name      = "id"
    position  = 0
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"id\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "user_name"
    position  = 1
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"user_name\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "city"
    position  = 2
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"city\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "pageviews"
    position  = 3
    type_name = "LONG"
    type_text = "bigint"
    type_json = "{\"name\":\"pageviews\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "orders"
    position  = 4
    type_name = "LONG"
    type_text = "bigint"
    type_json = "{\"name\":\"orders\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "total_orders_value"
    position  = 5
    type_name = "DOUBLE"
    type_text = "double"
    type_json = "{\"name\":\"total_orders_value\",\"type\":\"double\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "avg_order_value"
    position  = 6
    type_name = "DOUBLE"
    type_text = "double"
    type_json = "{\"name\":\"avg_order_value\",\"type\":\"double\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "total_items"
    position  = 7
    type_name = "LONG"
    type_text = "bigint"
    type_json = "{\"name\":\"total_items\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "avg_stars"
    position  = 8
    type_name = "DOUBLE"
    type_text = "double"
    type_json = "{\"name\":\"avg_stars\",\"type\":\"double\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "is_vip"
    position  = 9
    type_name = "BOOLEAN"
    type_text = "boolean"
    type_json = "{\"name\":\"is_vip\",\"type\":\"boolean\",\"nullable\":true,\"metadata\":{}}"
  }
}
