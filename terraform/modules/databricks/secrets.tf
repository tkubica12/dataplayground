resource "databricks_secret_scope" "jdbc" {
  name = "jdbc"
}

data "azurerm_key_vault_secret" "azuresql" { 
  name         = "sqlpassword"
  key_vault_id = var.keyvault_id
}

resource "databricks_secret" "azuresql" {
  key          = "azuresql"
  string_value = data.azurerm_key_vault_secret.azuresql.value
  scope        = databricks_secret_scope.jdbc.id
}