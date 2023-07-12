terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>1"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~>1"
    }
  }

  backend "azurerm" {
    resource_group_name  = "base"
    storage_account_name = "tkubicastore"
    container_name       = "tfstate"
    key                  = "dataplayground.databricks.tfstate"
    subscription_id      = "d3b7888f-c26e-4961-a976-ff9d5b31dfd3"
    use_oidc             = true
    client_id            = "411ef6e2-111c-4d86-ad39-bc8d1d9a9136"
    tenant_id            = "d6af5f85-2a50-4370-b4b5-9b9a55bcb0dc"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }
  }
}

provider "databricks" {
  host = module.databricks.databricks_domain_id
}
