locals {
  IngestData = <<JSON
{
	"name": "IngestData",
	"properties": {
		"type": "MappingDataFlow",
		"typeProperties": {
			"sources": [
				{
					"name": "users"
				},
				{
					"name": "vipusers"
				},
				{
					"name": "products"
				},
				{
					"name": "orders"
				},
				{
					"name": "items"
				}
			],
			"sinks": [
				{
					"name": "usersSilver"
				},
				{
					"name": "vipusersSilver"
				},
				{
					"name": "productsSilver"
				},
				{
					"name": "ordersSilver"
				},
				{
					"name": "itemsSilver"
				}
			],
			"transformations": [],
			"scriptLines": [
				"source(allowSchemaDrift: true,",
				"     validateSchema: false,",
				"     enableCdc: true,",
				"     mode: 'read',",
				"     fileSystem: 'bronze',",
				"     folderPath: 'users/users.json') ~> users",
				"source(allowSchemaDrift: true,",
				"     validateSchema: false,",
				"     enableCdc: true,",
				"     mode: 'read',",
				"     fileSystem: 'bronze',",
				"     folderPath: 'users/vip.json') ~> vipusers",
				"source(allowSchemaDrift: true,",
				"     validateSchema: false,",
				"     enableCdc: true,",
				"     mode: 'read',",
				"     fileSystem: 'bronze',",
				"     folderPath: 'products') ~> products",
				"source(allowSchemaDrift: true,",
				"     validateSchema: false) ~> orders",
				"source(allowSchemaDrift: true,",
				"     validateSchema: false) ~> items",
				"users sink(allowSchemaDrift: true,",
				"     validateSchema: false,",
				"     skipDuplicateMapInputs: true,",
				"     skipDuplicateMapOutputs: true,",
				"     format: 'delta',",
				"     fileSystem: 'silver',",
				"     folderPath: 'users',",
				"     mergeSchema: false,",
				"     autoCompact: false,",
				"     optimizedWrite: false,",
				"     vacuum: 0,",
				"     preCommands: [],",
				"     postCommands: []) ~> usersSilver",
				"vipusers sink(allowSchemaDrift: true,",
				"     validateSchema: false,",
				"     skipDuplicateMapInputs: true,",
				"     skipDuplicateMapOutputs: true,",
				"     format: 'delta',",
				"     fileSystem: 'silver',",
				"     folderPath: 'vipusers',",
				"     mergeSchema: false,",
				"     autoCompact: false,",
				"     optimizedWrite: false,",
				"     vacuum: 0,",
				"     preCommands: [],",
				"     postCommands: []) ~> vipusersSilver",
				"products sink(allowSchemaDrift: true,",
				"     validateSchema: false,",
				"     skipDuplicateMapInputs: true,",
				"     skipDuplicateMapOutputs: true,",
				"     format: 'delta',",
				"     fileSystem: 'silver',",
				"     folderPath: 'products',",
				"     mergeSchema: false,",
				"     autoCompact: false,",
				"     optimizedWrite: false,",
				"     vacuum: 0,",
				"     preCommands: [],",
				"     postCommands: []) ~> productsSilver",
				"orders sink(allowSchemaDrift: true,",
				"     validateSchema: false,",
				"     skipDuplicateMapInputs: true,",
				"     skipDuplicateMapOutputs: true,",
				"     format: 'delta',",
				"     fileSystem: 'silver',",
				"     folderPath: 'orders',",
				"     mergeSchema: false,",
				"     autoCompact: false,",
				"     optimizedWrite: false,",
				"     vacuum: 0,",
				"     preCommands: [],",
				"     postCommands: []) ~> ordersSilver",
				"items sink(allowSchemaDrift: true,",
				"     validateSchema: false,",
				"     skipDuplicateMapInputs: true,",
				"     skipDuplicateMapOutputs: true,",
				"     format: 'delta',",
				"     fileSystem: 'silver',",
				"     folderPath: 'items',",
				"     mergeSchema: false,",
				"     autoCompact: false,",
				"     optimizedWrite: false,",
				"     vacuum: 0,",
				"     preCommands: [],",
				"     postCommands: []) ~> itemsSilver"
			]
		}
	}
}
JSON
}

resource "null_resource" "data_flow_ingest_data" {
  provisioner "local-exec" {
    command = "az synapse data-flow create -n $name --workspace-name $workspace_name --file '${local.IngestData}'"
    environment = {
      workspace_name = azurerm_synapse_workspace.main.name
      name           = jsondecode(local.IngestData).name
    }
  }
  
  triggers = {
    always_run = "${timestamp()}"
  }
}

output "test" {
  value = jsondecode(local.IngestData).name
}
