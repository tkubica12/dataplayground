// Resource Group
resource "azurerm_resource_group" "main" {
  name     = "data-demo"
  location = var.location
}

// Generate random prefix
resource "random_string" "random" {
  length  = 12
  special = false
  lower   = true
  upper   = false
  numeric = false
}

// Data Lake and data generation
module "data_lake" {
  source              = "./modules/data_lake"
  name_prefix         = random_string.random.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  users_count         = 5000000
  products_count      = 100000
  orders_count        = 100000000
}
