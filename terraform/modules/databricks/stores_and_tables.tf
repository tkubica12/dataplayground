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
  metastore_id = databricks_metastore.main.id
  name         = "mycatalog"

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
  catalog_name = databricks_catalog.main.id
  name         = "mydb"
}

// Storage access
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

// TABLE orders
resource "databricks_table" "orders" {
  name               = "orders"
  catalog_name       = databricks_catalog.main.id
  schema_name        = databricks_schema.main.name
  table_type         = "MANAGED"
  data_source_format = "DELTA"
  owner              = "account users"

  column {
    name      = "orderId"
    position  = 0
    type_name = "INT"
    type_text = "int"
    type_json = "{\"name\":\"orderId\",\"type\":\"integer\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "userId"
    position  = 1
    type_name = "INT"
    type_text = "int"
    type_json = "{\"name\":\"userId\",\"type\":\"integer\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "orderDate"
    position  = 2
    type_name = "TIMESTAMP"
    type_text = "timestamp"
    type_json = "{\"name\":\"orderDate\",\"type\":\"timestamp\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "oderValue"
    position  = 3
    type_name = "DOUBLE"
    type_text = "double"
    type_json = "{\"name\":\"orderValue\",\"type\":\"double\",\"nullable\":true,\"metadata\":{}}"
  }
}

// TABLE items
resource "databricks_table" "items" {
  name               = "items"
  catalog_name       = databricks_catalog.main.id
  schema_name        = databricks_schema.main.name
  table_type         = "MANAGED"
  data_source_format = "DELTA"
  owner              = "account users"

  column {
    name      = "orderId"
    position  = 0
    type_name = "INT"
    type_text = "int"
    type_json = "{\"name\":\"orderId\",\"type\":\"integer\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "rowId"
    position  = 1
    type_name = "INT"
    type_text = "int"
    type_json = "{\"name\":\"rowId\",\"type\":\"integer\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "productId"
    position  = 2
    type_name = "INT"
    type_text = "int"
    type_json = "{\"name\":\"productId\",\"type\":\"integer\",\"nullable\":true,\"metadata\":{}}"
  }
}

// TABLE products
resource "databricks_table" "products" {
  name               = "products"
  catalog_name       = databricks_catalog.main.id
  schema_name        = databricks_schema.main.name
  table_type         = "MANAGED"
  data_source_format = "DELTA"
  owner              = "account users"

  column {
    name      = "description"
    position  = 0
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"description\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "id"
    position  = 1
    type_name = "LONG"
    type_text = "bigint"
    type_json = "{\"name\":\"id\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "name"
    position  = 2
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"name\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "pages"
    position  = 3
    type_name = "ARRAY"
    type_text = "array<string>"
    type_json = "{\"name\":\"pages\",\"type\":{\"type\":\"array\",\"elementType\":\"string\",\"containsNull\":true},\"nullable\":true,\"metadata\":{}}"
  }
}

// TABLE vipusers
resource "databricks_table" "vipusers" {
  name               = "vipusers"
  catalog_name       = databricks_catalog.main.id
  schema_name        = databricks_schema.main.name
  table_type         = "MANAGED"
  data_source_format = "DELTA"
  owner              = "account users"

  column {
    name      = "id"
    position  = 0
    type_name = "LONG"
    type_text = "bigint"
    type_json = "{\"name\":\"id\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}"
  }
}

// TABLE users
resource "databricks_table" "users" {
  name               = "users"
  catalog_name       = databricks_catalog.main.id
  schema_name        = databricks_schema.main.name
  table_type         = "MANAGED"
  data_source_format = "DELTA"
  owner              = "account users"

  column {
    name      = "administrative_unit"
    position  = 0
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"administrative_unit\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "birth_number"
    position  = 1
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"birth_number\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "city"
    position  = 2
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"city\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "description"
    position  = 3
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"description\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "id"
    position  = 4
    type_name = "LONG"
    type_text = "bigint"
    type_json = "{\"name\":\"id\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "jobs"
    position  = 5
    type_name = "ARRAY"
    type_text = "array<string>"
    type_json = "{\"name\":\"jobs\",\"type\":{\"type\":\"array\",\"elementType\":\"string\",\"containsNull\":true},\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "name"
    position  = 6
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"name\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "phone_number"
    position  = 7
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"phone_number\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "street_address"
    position  = 8
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"street_address\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "user_name"
    position  = 9
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"user_name\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
}

// TABLE stars
resource "databricks_table" "stars" {
  name               = "stars"
  catalog_name       = databricks_catalog.main.id
  schema_name        = databricks_schema.main.name
  table_type         = "MANAGED"
  data_source_format = "DELTA"
  owner              = "account users"

  column {
    name      = "user_id"
    position  = 0
    type_name = "LONG"
    type_text = "bigint"
    type_json = "{\"name\":\"user_id\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "stars"
    position  = 1
    type_name = "LONG"
    type_text = "bigint"
    type_json = "{\"name\":\"stars\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "EventProcessedUtcTime"
    position  = 2
    type_name = "TIMESTAMP"
    type_text = "timestamp"
    type_json = "{\"name\":\"EventProcessedUtcTime\",\"type\":\"timestamp\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "PartitionId"
    position  = 3
    type_name = "LONG"
    type_text = "bigint"
    type_json = "{\"name\":\"PartitionId\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "EventEnqueuedUtcTime"
    position  = 4
    type_name = "TIMESTAMP"
    type_text = "timestamp"
    type_json = "{\"name\":\"EventEnqueuedUtcTime\",\"type\":\"timestamp\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "year"
    position  = 5
    type_name = "INT"
    type_text = "int"
    type_json = "{\"name\":\"year\",\"type\":\"integer\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "month"
    position  = 6
    type_name = "INT"
    type_text = "int"
    type_json = "{\"name\":\"month\",\"type\":\"integer\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "day"
    position  = 7
    type_name = "INT"
    type_text = "int"
    type_json = "{\"name\":\"day\",\"type\":\"integer\",\"nullable\":true,\"metadata\":{}}"
  }
}

// TABLE pageviews
resource "databricks_table" "pageviews" {
  name               = "pageviews"
  catalog_name       = databricks_catalog.main.id
  schema_name        = databricks_schema.main.name
  table_type         = "MANAGED"
  data_source_format = "DELTA"
  owner              = "account users"

  column {
    name      = "user_id"
    position  = 0
    type_name = "LONG"
    type_text = "bigint"
    type_json = "{\"name\":\"user_id\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "http_method"
    position  = 1
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"http_method\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "uri"
    position  = 2
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"uri\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "client_ip"
    position  = 3
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"client_ip\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "user_agent"
    position  = 4
    type_name = "STRING"
    type_text = "string"
    type_json = "{\"name\":\"user_agent\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "latency"
    position  = 5
    type_name = "DOUBLE"
    type_text = "double"
    type_json = "{\"name\":\"latency\",\"type\":\"double\",\"nullable\":true,\"metadata\":{}}"
  }
    column {
    name      = "EventProcessedUtcTime"
    position  = 6
    type_name = "TIMESTAMP"
    type_text = "timestamp"
    type_json = "{\"name\":\"EventProcessedUtcTime\",\"type\":\"timestamp\",\"nullable\":true,\"metadata\":{}}"
  }
    column {
    name      = "PartitionId"
    position  = 7
    type_name = "LONG"
    type_text = "bigint"
    type_json = "{\"name\":\"PartitionId\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}"
  }
  column {
    name      = "EventEnqueuedUtcTime"
    position  = 8
    type_name = "TIMESTAMP"
    type_text = "timestamp"
    type_json = "{\"name\":\"EventEnqueuedUtcTime\",\"type\":\"timestamp\",\"nullable\":true,\"metadata\":{}}"
  }
}

