data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "main" {
  name                     = var.name_prefix
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_key_vault" "main" {
  name                      = var.name_prefix
  location                  = var.location
  resource_group_name       = var.resource_group_name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true
}

resource "azurerm_container_registry" "main" {
  name                = var.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_application_insights" "main" {
  name                = var.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
}

resource "azurerm_machine_learning_workspace" "main" {
  name                          = var.name_prefix
  friendly_name                 = var.name_prefix
  location                      = var.location
  resource_group_name           = var.resource_group_name
  application_insights_id       = azurerm_application_insights.main.id
  key_vault_id                  = azurerm_key_vault.main.id
  storage_account_id            = azurerm_storage_account.main.id
  container_registry_id         = azurerm_container_registry.main.id
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }
}

# resource "azurerm_role_assignment" "storage" {
#   scope                = azurerm_storage_account.main.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_machine_learning_workspace.main.identity.0.principal_id
# }

# resource "azurerm_role_assignment" "keyvault" {
#   scope                = azurerm_key_vault.main.id
#   role_definition_name = "Key Vault Administrator"
#   principal_id         = azurerm_machine_learning_workspace.main.identity.0.principal_id
# }

resource "azurerm_role_assignment" "compute" {
  scope                = azurerm_machine_learning_workspace.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_machine_learning_compute_instance.main.identity.0.principal_id
}

resource "azurerm_machine_learning_compute_instance" "main" {
  name                          = "${var.name_prefix}-instance"
  location                      = var.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.main.id
  virtual_machine_size          = "STANDARD_DS2_V2"
  authorization_type            = "personal"

  identity {
    type = "SystemAssigned"
  }
}

# resource "azurerm_machine_learning_compute_cluster" "main" {
#   name                          = "${var.name_prefix}-cluster"
#   location                      = var.location
#   vm_priority                   = "Dedicated"
#   vm_size                       = "Standard_DS2_v2"
#   machine_learning_workspace_id = azurerm_machine_learning_workspace.main.id

#   scale_settings {
#     min_node_count                       = 0
#     max_node_count                       = 1
#     scale_down_nodes_after_idle_duration = "PT30M" 
#   }

#   identity {
#     type = "SystemAssigned"
#   }
# }
