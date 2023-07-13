// Storage SAS for generators
data "azurerm_storage_account_blob_container_sas" "storage_sas_bronze" {
  connection_string = azurerm_storage_account.main.primary_connection_string
  container_name    = azurerm_storage_container.bronze.name
  https_only        = true

  start  = "2018-03-21"
  expiry = "2200-03-21"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}

// Generators with output to storage
resource "azurerm_container_group" "generate_users" {
  name                = "generateusers"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "None"
  os_type             = "Linux"
  restart_policy      = "Never"

  container {
    name   = "container"
    image  = "ghcr.io/tkubica12/generate_users:latest"
    cpu    = "1"
    memory = "2"

    environment_variables = {
      "COUNT"     = tostring(var.users_count)
      "VIP_COUNT" = tostring(var.vip_users_count)
    }

    secure_environment_variables = {
      "STORAGE_SAS" = "${azurerm_storage_account.main.primary_dfs_endpoint}${azurerm_storage_container.bronze.name}/${data.azurerm_storage_account_blob_container_sas.storage_sas_bronze.sas}"
    }
  }
}

resource "azurerm_container_group" "generate_products" {
  name                = "generateproducts"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "None"
  os_type             = "Linux"
  restart_policy      = "Never"

  container {
    name   = "container"
    image  = "ghcr.io/tkubica12/generate_products:latest"
    cpu    = "1"
    memory = "2"

    environment_variables = {
      "COUNT" = tostring(var.products_count)
      "RATE"  = tostring(var.products_rate)
    }

    secure_environment_variables = {
      "STORAGE_SAS" = "${azurerm_storage_account.main.primary_dfs_endpoint}${azurerm_storage_container.bronze.name}/${data.azurerm_storage_account_blob_container_sas.storage_sas_bronze.sas}"
    }
  }
}

// Authorization to Event Hub for generators
resource "azurerm_eventhub_authorization_rule" "pageviewsSender" {
  name                = "pageviewsSender"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  eventhub_name       = azurerm_eventhub.pageviews.name
  listen              = false
  send                = true
  manage              = false
}

resource "azurerm_eventhub_authorization_rule" "starsSender" {
  name                = "starsSender"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  eventhub_name       = azurerm_eventhub.stars.name
  listen              = false
  send                = true
  manage              = false
}

resource "azurerm_container_group" "stream_pageviews" {
  name                = "stream"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "None"
  os_type             = "Linux"
  restart_policy      = "Always"

  container {
    name   = "container"
    image  = "ghcr.io/tkubica12/stream_pageviews:latest"
    cpu    = "1"
    memory = "2"

    environment_variables = {
      "EVENTHUB_NAMESPACE" = azurerm_eventhub_namespace.main.name
      "USER_MAX_ID"        = tostring(var.users_count - 1)
    }

    secure_environment_variables = {
      "EVENTHUB_CONNECTION_STRING_PAGEVIEWS" = azurerm_eventhub_authorization_rule.pageviewsSender.primary_connection_string
      "EVENTHUB_CONNECTION_STRING_STARS"     = azurerm_eventhub_authorization_rule.starsSender.primary_connection_string
    }
  }
}

// Generators with output to SQL
resource "azurerm_container_group" "generate_orders" {
  name                = "generateorders"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "None"
  os_type             = "Linux"
  restart_policy      = "Never"

  container {
    name   = "container"
    image  = "ghcr.io/tkubica12/generate_orders:latest"
    cpu    = "1"
    memory = "2"

    environment_variables = {
      "COUNT"          = tostring(var.orders_count)
      "RATE"           = tostring(var.orders_rate)
      "USER_MAX_ID"    = tostring(var.users_count - 1)
      "PRODUCT_MAX_ID" = tostring(var.products_count - 1)
      "SQL_SERVER"     = azurerm_mssql_server.main.fully_qualified_domain_name
      "SQL_DATABASE"   = azurerm_mssql_database.orders.name
      "SQL_USER"       = azurerm_mssql_server.main.administrator_login
    }

    secure_environment_variables = {
      "SQL_PASSWORD" = azurerm_mssql_server.main.administrator_login_password
    }
  }
}

