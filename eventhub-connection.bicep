param connections_eventhubconn_name string = 'eventhubconn'

@secure()
param eventHubNamespaceConnectionString string

resource connections_eventhubconn_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_eventhubconn_name
  location: 'eastus'
  kind: 'V1'
  properties: {
    displayName: connections_eventhubconn_name
    parameterValues: {
      connectionString: eventHubNamespaceConnectionString
    }
    statuses: [
      {
        status: 'Connected'
      }
    ]
    customParameterValues: {}
    nonSecretParameterValues: {}
    createdTime: '2025-12-18T08:30:15.6093368Z'
    changedTime: '2025-12-18T08:52:24.7230032Z'
    api: {
      name: 'eventhubs'
      displayName: 'Hub eventi'
      description: 'Connettiti a Hub eventi di Azure per inviare e ricevere eventi.'
      iconUri: 'https://conn-afd-prod-endpoint-bmc9bqahasf3grgk.b01.azurefd.net/v1.0.1767/1.0.1767.4341/eventhubs/icon.png'
      brandColor: '#c4d5ff'
      id: '/subscriptions/0b452223-7c11-4015-b9a2-e94bdf285f1f/providers/Microsoft.Web/locations/eastus/managedApis/eventhubs'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}
