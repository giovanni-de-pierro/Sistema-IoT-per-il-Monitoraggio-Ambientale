resource outlookConn 'Microsoft.Web/connections@2016-06-01' = {
  name: 'outlookconn'
  location: 'eastus'
  properties: {
    displayName: 'outlookconn'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', 'eastus', 'outlook')
    }
  }
}
