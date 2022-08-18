terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "~>1"
    }
  }
}

provider "databricks" {
  host = azurerm_databricks_workspace.main.workspace_url
}