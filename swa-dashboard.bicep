param swa_dashboard_name string
param cosmos_connection_string string
param db_name string
param container_name string
param repo_url string

@secure()
param github_token string

resource swa_dashboard_resource 'Microsoft.Web/staticSites@2024-11-01' = {
  name: swa_dashboard_name
  location: 'East US 2'
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    repositoryUrl: repo_url
    branch: 'main'
    repositoryToken: github_token
    provider: 'GitHub'
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    enterpriseGradeCdnStatus: 'Disabled'
    buildProperties: {
      appLocation: 'www'
      apiLocation: 'api'
    }
  }
}

resource swa_settings 'Microsoft.Web/staticSites/config@2024-11-01' = {
  parent: swa_dashboard_resource
  name: 'appsettings'
  properties: {
    CosmosDBConnectionString: cosmos_connection_string
    DB_NAME: db_name
    DB_CONTAINER_NAME: container_name
    PYTHON_VERSION: '3.10'
  }
}
