// Storage Account
resource "azurerm_storage_account" "main" {
  name                     = var.name_prefix
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
}

// Storage containers
resource "azurerm_storage_container" "bronze" {
  name                  = "bronze"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "silver" {
  name                  = "silver"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "gold" {
  name                  = "gold"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

// Container SAS
data "azurerm_storage_account_blob_container_sas" "storage_sas_bronze" {
  connection_string = azurerm_storage_account.main.primary_connection_string
  container_name    = azurerm_storage_container.bronze.name
  https_only        = true

  start  = "2018-03-21"
  expiry = "2200-03-21"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}

# // SAS for Databricks
# data "azurerm_storage_account_sas" "storage_sas_databricks" {
#   connection_string = azurerm_storage_account.main.primary_connection_string
#   https_only        = true
#   signed_version    = "2021-06-08"

#   resource_types {
#     service   = true
#     container = true
#     object    = true
#   }

#   services {
#     blob  = true
#     queue = true
#     table = true
#     file  = true
#   }

#   start  = "2018-03-21T00:00:00Z"
#   expiry = "2050-03-21T00:00:00Z"

#   permissions {
#     read    = true
#     write   = true
#     delete  = true
#     list    = true
#     add     = true
#     create  = true
#     update  = true
#     process = true
#     tag     = false
#     filter  = false
#   }
# }

// Managed Identity with storage writer rights
resource "azurerm_user_assigned_identity" "storage-writer" {
  name                = "storage-writer"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "random_uuid" "storage-write" {
}

resource "azurerm_role_assignment" "storage-write" {
  name                 = random_uuid.storage-write.result
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.storage-writer.principal_id
}

// Add current account RBAC
data "azurerm_client_config" "storage" {
}

resource "random_uuid" "storage-currentuser" {
}

resource "azurerm_role_assignment" "storage-currentuser" {
  name                 = random_uuid.storage-currentuser.result
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.storage.object_id
}







