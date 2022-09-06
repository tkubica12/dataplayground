// Create Key Vault
resource "azurerm_key_vault" "main" {
  name                       = random_string.random.result
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  enable_rbac_authorization  = true
  tenant_id                  = data.azurerm_client_config.main.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"
}



// Assign current user as admin
data "azurerm_client_config" "main" {
}

resource "azurerm_role_assignment" "currentuser-kv" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.main.object_id
}


