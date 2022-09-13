terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~>1"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~>0"
    }
  }
}

provider "databricks" {
  host = azurerm_databricks_workspace.main.workspace_url
}
