param namespace_name string
param location string

// Namespace
resource ehNamespace 'Microsoft.EventHub/namespaces@2024-05-01-preview' = {
  name: namespace_name
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 1
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: true
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    kafkaEnabled: true
  }
}

// Policy di root
resource ehRootPolicy 'Microsoft.EventHub/namespaces/authorizationrules@2024-05-01-preview' = {
  parent: ehNamespace
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

// Event Hub
resource ehAlert 'Microsoft.EventHub/namespaces/eventhubs@2024-05-01-preview' = {
  parent: ehNamespace
  name: '${namespace_name}alert'
  properties: {
    messageTimestampDescription: {
      timestampType: 'LogAppend'
    }
    retentionDescription: {
      cleanupPolicy: 'Delete'
      retentionTimeInHours: 1
    }
    messageRetentionInDays: 1
    partitionCount: 1
    status: 'Active'
  }
}

// Network rules (default)
resource ehNetwork 'Microsoft.EventHub/namespaces/networkrulesets@2024-05-01-preview' = {
  parent: ehNamespace
  name: 'default'
  properties: {
    publicNetworkAccess: 'Enabled'
    defaultAction: 'Allow'
    virtualNetworkRules: []
    ipRules: []
    trustedServiceAccessEnabled: false
  }
}

// Policy per Stream Analytics
resource ehStreamPolicy 'Microsoft.EventHub/namespaces/eventhubs/authorizationrules@2024-05-01-preview' = {
  parent: ehAlert
  name: 'IoTStreamJobPolicy'
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}
