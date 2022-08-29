resource "azapi_resource" "pageviews" {
  type                      = "Microsoft.StreamAnalytics/streamingjobs/inputs@2021-10-01-preview"
  name                      = "pageviews"
  parent_id                 = azurerm_stream_analytics_job.main.id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      type : "Stream"
      datasource : {
        type : "Microsoft.EventHub/EventHub",
        properties : {
          eventHubName : var.eventhub_name_pageviews
          serviceBusNamespace : var.eventhub_namespace_name
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

resource "azapi_resource" "stars" {
  type                      = "Microsoft.StreamAnalytics/streamingjobs/inputs@2021-10-01-preview"
  name                      = "stars"
  parent_id                 = azurerm_stream_analytics_job.main.id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      type : "Stream"
      datasource : {
        type : "Microsoft.EventHub/EventHub",
        properties : {
          eventHubName : var.eventhub_name_stars
          serviceBusNamespace : var.eventhub_namespace_name
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

resource "azapi_resource" "input_vip" {
  type                      = "Microsoft.StreamAnalytics/streamingjobs/inputs@2021-10-01-preview"
  name                      = "vip"
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
          pathPattern : "users/vip.json"
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

