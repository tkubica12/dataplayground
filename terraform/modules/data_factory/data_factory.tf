resource "azurerm_data_factory" "main" {
  name                = var.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.kv-reader_id,
      var.storage-writer_id,
      var.databricks_df_access_id
    ]
  }
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

resource "azapi_resource" "storage-writer" {
  type                      = "Microsoft.DataFactory/factories/credentials@2018-06-01"
  name                      = "storage-writer"
  parent_id                 = azurerm_data_factory.main.id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      type : "ManagedIdentity"
      typeProperties : {
        resourceId : var.storage-writer_id
      }
    }
  })

  depends_on = [
    azurerm_data_factory.main
  ]
}

resource "azapi_resource" "databricks_df_access" {
  type                      = "Microsoft.DataFactory/factories/credentials@2018-06-01"
  name                      = "databricks_df_access"
  parent_id                 = azurerm_data_factory.main.id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      type : "ManagedIdentity"
      typeProperties : {
        resourceId : var.databricks_df_access_id
      }
    }
  })

  depends_on = [
    azurerm_data_factory.main
  ]
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                           = "data_factory"
  target_resource_id             = azurerm_data_factory.main.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  log {
    category = "ActivityRuns"
    enabled  = true

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "PipelineRuns"
    enabled  = true

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "TriggerRuns"
    enabled  = true

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "SSISIntegrationRuntimeLogs"
    enabled  = true

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "SSISPackageEventMessageContext"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "SSISPackageEventMessages"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "SSISPackageExecutionDataStatistics"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "SSISPackageExecutionComponentPhases"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "SSISPackageExecutableStatistics"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "SandboxActivityRuns"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "SandboxPipelineRuns"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }
  
  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }
}
