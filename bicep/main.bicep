var location = resourceGroup().location

// Data Lake
resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: uniqueString(resourceGroup().id)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' existing = {
  name: 'default'
  parent: storage
}

resource bronze 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: 'bronze'
  parent: blobService
}

// Outputs
output storageAccountName string = storage.name
