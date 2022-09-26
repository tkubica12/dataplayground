locals {
  DataPipeline = <<JSON
{
	"name": "DataPipeline",
	"properties": {
		"activities": [
			{
				"name": "IngestData",
				"type": "ExecuteDataFlow",
				"dependsOn": [],
				"policy": {
					"timeout": "0.12:00:00",
					"retry": 0,
					"retryIntervalInSeconds": 30,
					"secureOutput": false,
					"secureInput": false
				},
				"userProperties": [],
				"typeProperties": {
					"dataflow": {
						"referenceName": "IngestData",
						"type": "DataFlowReference"
					},
					"compute": {
						"coreCount": 8,
						"computeType": "General"
					},
					"traceLevel": "Fine",
					"runConcurrently": true,
					"continueOnError": true
				}
			}
		],
		"annotations": []
	},
	"type": "Microsoft.Synapse/workspaces/pipelines"
}
JSON
}

resource "null_resource" "pipeline_data_pipeline" {
  provisioner "local-exec" {
    command = "az synapse pipeline create -n $name --workspace-name $workspace_name --file '${local.DataPipeline}'"
    environment = {
      workspace_name = azurerm_synapse_workspace.main.name
      name           = jsondecode(local.DataPipeline).name
    }
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    null_resource.data_flow_ingest_data
  ]
}
