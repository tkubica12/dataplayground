resource "azurerm_data_factory" "main" {
  name                = var.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name

  identity {
    type         = "UserAssigned"
    identity_ids = [var.kv-reader_id]
  }

  #   github_configuration {
  #     account_name    = "tkubica12"
  #     repository_name = "data-demo"
  #     branch_name     = "main"
  #     git_url         = "https://github.com"
  #     root_folder     = "/datafactory"
  #   }
}

resource "azapi_resource" "dfcredentials" {
  type                      = "Microsoft.DataFactory/factories/credentials@2018-06-01"
  name                      = "kv-reader"
  parent_id                 = azurerm_data_factory.main.id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      type : "ManagedIdentity"
      typeProperties : {
        resourceId : var.kv-reader_id
      }
    }
  })

  depends_on = [
    azurerm_data_factory.main
  ]
}
