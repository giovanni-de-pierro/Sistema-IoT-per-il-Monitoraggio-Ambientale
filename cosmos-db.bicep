param cosmos_db_account_name string
param location string
param databaseName string
param containerName string

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2025-05-01-preview' = {
  name: cosmos_db_account_name
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    enableFreeTier: true
    publicNetworkAccess: 'Enabled'
  }
}

resource iotDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2025-05-01-preview' = {
  parent: cosmosAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource deviceTelemetry 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-05-01-preview' = {
  parent: iotDb
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: ['/deviceId']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
      }
      conflictResolutionPolicy: {
        mode: 'LastWriterWins'
        conflictResolutionPath: '/_ts'
      }
    }
  }
}
