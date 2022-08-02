resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "![]{}<>:?"
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
}

resource "azurerm_mssql_server" "main" {
  name                         = var.name_prefix
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "tomas"
  administrator_login_password = random_password.password.result
}

resource "azurerm_mssql_database" "orders" {
  name                        = "orders"
  server_id                   = azurerm_mssql_server.main.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  auto_pause_delay_in_minutes = 60
  max_size_gb                 = 1024
  read_scale                  = false
  sku_name                    = "GP_S_Gen5_2"
  zone_redundant              = false
  storage_account_type        = "Local"
}
