// Storage for Synapse
resource "azurerm_storage_account" "main" {
  name                     = "synapse${var.name_prefix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

// Storage container
resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  name               = "synapse"
  storage_account_id = azurerm_storage_account.main.id
}

// Get client details
data "azurerm_client_config" "current" {}

// Generate SQL password
resource "random_password" "sql" {
  length           = 16
  special          = true
  override_special = "_%@-"
  upper            = true
  lower            = true
  numeric          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

// Store password in Key Vault
resource "azurerm_key_vault_secret" "sql" {
  name         = "sql"
  value        = random_password.sql.result
  key_vault_id = var.keyvault_id
}

// Synapse workspace
data "azuread_user" "current" {
  object_id = data.azurerm_client_config.current.object_id
}

resource "azurerm_synapse_workspace" "main" {
  name                                 = "s${var.name_prefix}"
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse.id
  sql_administrator_login              = "sqladmin"
  sql_administrator_login_password     = random_password.sql.result
  managed_virtual_network_enabled      = true
  public_network_access_enabled        = true
  managed_resource_group_name          = "${var.resource_group_name}-synapse"

  identity {
    type = "SystemAssigned"
  }

  aad_admin = [
    {
      login     = data.azuread_user.current.user_principal_name
      object_id = data.azurerm_client_config.current.object_id
      tenant_id = data.azurerm_client_config.current.tenant_id
    }
  ]

  # github_repo {
  #   account_name    = "tkubica12"
  #   branch_name     = "main"
  #   repository_name = "dataplayground"
  #   root_folder     = "/synapse"
  # }

  # lifecycle {
  #   ignore_changes = [
  #     github_repo.0.last_commit_id
  #   ]
  # }
}

resource "azurerm_synapse_firewall_rule" "all" {
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

