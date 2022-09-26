locals {
  Every15minutes = <<JSON
{
	"name": "Every15minutes",
	"properties": {
		"annotations": [],
		"runtimeState": "Stopped",
		"pipelines": [
			{
				"pipelineReference": {
					"referenceName": "DataPipeline",
					"type": "PipelineReference"
				}
			}
		],
		"type": "ScheduleTrigger",
		"typeProperties": {
			"recurrence": {
				"frequency": "Minute",
				"interval": 15,
				"startTime": "2022-09-23T04:01:00Z",
				"timeZone": "UTC"
			}
		}
	}
}
JSON
}

resource "null_resource" "trigger_every_15_minutes" {
  provisioner "local-exec" {
    command = "az synapse trigger create -n $name --workspace-name $workspace_name --file '${local.Every15minutes}'"
    environment = {
      workspace_name = azurerm_synapse_workspace.main.name
      name           = jsondecode(local.Every15minutes).name
    }
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
	null_resource.pipeline_data_pipeline
  ]
}
