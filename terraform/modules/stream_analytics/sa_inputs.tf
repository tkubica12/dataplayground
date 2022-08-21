resource "azurerm_stream_analytics_stream_input_eventhub" "eventhub" {
  name                         = "pageviews"
  stream_analytics_job_name    = azurerm_stream_analytics_job.main.name
  resource_group_name          = var.resource_group_name
  eventhub_consumer_group_name = azurerm_eventhub_consumer_group.eventhub.name
  eventhub_name                = var.eventhub_name
  servicebus_namespace         = var.eventhub_namespace_name
  shared_access_policy_key     = azurerm_eventhub_namespace_authorization_rule.eventhub.primary_key
  shared_access_policy_name    = azurerm_eventhub_namespace_authorization_rule.eventhub.name

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

resource "azapi_resource" "input_users" {
  type                      = "Microsoft.StreamAnalytics/streamingjobs/inputs@2021-10-01-preview"
  name                      = "users"
  parent_id                 = azurerm_stream_analytics_job.main.id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      type : "Reference"
      datasource : {
        type : "Microsoft.Storage/Blob",
        properties : {
          storageAccounts : [
            {
              accountName : var.datalake_name
            }
          ]
          container : "bronze"
          pathPattern : "users/users.json"
          authenticationMode : "Msi"
        }
      }
      compression : {
        type : "None"
      }
      serialization : {
        type : "Json"
        properties : {
          encoding : "UTF8"
        }
      }
    }
  })
}

