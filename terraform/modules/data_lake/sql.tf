resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "![]{}<>:?"
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
}

data "azurerm_client_config" "main" {
}

resource "azurerm_mssql_server" "main" {
  name                         = var.name_prefix
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "tomas"
  administrator_login_password = random_password.password.result

  azuread_administrator {
    login_username = data.azurerm_client_config.main.client_id
    object_id      = data.azurerm_client_config.main.object_id
  }
}

resource "azurerm_key_vault_secret" "sqlpassword" {
  name         = "sqlpassword"
  value        = azurerm_mssql_server.main.administrator_login_password
  key_vault_id = var.keyvault_id
}

resource "azurerm_key_vault_secret" "dfsqlconnection" {
  name         = "dfsqlconnection"
  value        = "Data Source=${azurerm_mssql_server.main.fully_qualified_domain_name};Initial Catalog=${azurerm_mssql_database.orders.name};Integrated Security=False;User ID=${azurerm_mssql_server.main.administrator_login};Password=${azurerm_mssql_server.main.administrator_login_password};"
  key_vault_id = var.keyvault_id
}

resource "azurerm_mssql_database" "orders" {
  name                        = "orders"
  server_id                   = azurerm_mssql_server.main.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  auto_pause_delay_in_minutes = 60
  max_size_gb                 = 500
  read_scale                  = false
  sku_name                    = "GP_S_Gen5_1"
  min_capacity                = 0.5
  zone_redundant              = false
  storage_account_type        = "Local"
}

resource "azurerm_mssql_firewall_rule" "azureservices" {
  name             = "AzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# resource "azurerm_mssql_firewall_rule" "all" {
#   name             = "all"
#   server_id        = azurerm_mssql_server.main.id
#   start_ip_address = "0.0.0.0"
#   end_ip_address   = "255.255.255.255"
# }


