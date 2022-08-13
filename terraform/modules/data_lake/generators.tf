

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
      "COUNT" = tostring(var.users_count)
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
    }

    secure_environment_variables = {
      "STORAGE_SAS" = "${azurerm_storage_account.main.primary_dfs_endpoint}${azurerm_storage_container.bronze.name}/${data.azurerm_storage_account_blob_container_sas.storage_sas_bronze.sas}"
    }
  }
}

resource "azurerm_container_group" "stream_pageviews" {
  name                = "streampageviews"
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
      "USER_MAX_ID"        = tostring(var.users_count -1)
    }

    secure_environment_variables = {
      "EVENTHUB_CONNECTION_STRING" = azurerm_eventhub_authorization_rule.pageviewsSender.primary_connection_string
    }
  }
}


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
      "USER_MAX_ID"    = tostring(var.users_count -1)
      "PRODUCT_MAX_ID" = tostring(var.products_count -1)
      "SQL_SERVER"     = azurerm_mssql_server.main.fully_qualified_domain_name
      "SQL_DATABASE"   = azurerm_mssql_database.orders.name
      "SQL_USER"       = azurerm_mssql_server.main.administrator_login
    }

    secure_environment_variables = {
      "SQL_PASSWORD" = azurerm_mssql_server.main.administrator_login_password
    }
  }
}

