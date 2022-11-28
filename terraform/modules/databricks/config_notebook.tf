# data "azurerm_key_vault_secret" "sql_password" { 
#   name         = "sqlpassword"
#   key_vault_id = var.keyvault_id
# }

locals {
  demo_include = <<CONTENT
spark.conf.set('demo.storage_account_name','${var.storage_account_name}')
demo_storage_account_name = "${var.storage_account_name}"

spark.conf.set('demo.event_hub_namespace_name','${var.eventhub_namespace_name}')
demo_event_hub_namespace_name = "${var.eventhub_namespace_name}"

CONTENT
}

resource "databricks_notebook" "demo_include" {
  content_base64 = base64encode(local.demo_include)
  language       = "PYTHON"
  path           = "/Shared/demo_include"
}