param streamAnalyticsJobName string
param location string
param iotHubName string
param cosmosAccountName string
param cosmosDatabase string
param cosmosContainer string

param eventHubNamespace string
param eventHubName string
param eventHubPolicyName string

@secure()
param sharedAccessPolicyKey string

@secure()
param eventHubPolicyKey string

resource saJob 'Microsoft.StreamAnalytics/streamingjobs@2021-10-01-preview' = {
  name: streamAnalyticsJobName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Standard'
    }
    jobType: 'Cloud'
    contentStoragePolicy: 'SystemAccount'
    compatibilityLevel: '1.2'
    eventsOutOfOrderPolicy: 'Adjust'
    outputErrorPolicy: 'Stop'
    transformation: {
      name: 'Transformation'
      properties: {
        streamingUnits: 3
        query: '''
          SELECT
            deviceId,
            temperature,
            humidity,
            timestamp
          INTO
            cosmosOutput
          FROM
            iotInput

          SELECT
              deviceId,
              temperature,
              humidity,
              timestamp,
              CASE WHEN temperature > 26 THEN 1 ELSE 0 END AS isHot,
              CASE WHEN temperature < 18 THEN 1 ELSE 0 END AS isCold,
              CASE WHEN humidity > 60 THEN 1 ELSE 0 END AS isHumid,
              CASE WHEN humidity < 30 THEN 1 ELSE 0 END AS isDry
          INTO
              eventHubAlertOutput
          FROM
              iotInput
          WHERE
              temperature > 26
              OR temperature < 18
              OR humidity > 60
              OR humidity < 30
        '''
      }
    }
  }
}

resource saInput 'Microsoft.StreamAnalytics/streamingjobs/inputs@2021-10-01-preview' = {
  parent: saJob
  name: 'iotInput'
  properties: {
    type: 'Stream'
    datasource: {
      type: 'Microsoft.Devices/IotHubs'
      properties: {
        iotHubNamespace: iotHubName
        sharedAccessPolicyName: 'service'
        sharedAccessPolicyKey: sharedAccessPolicyKey
        consumerGroupName: '$Default'
        endpoint: 'messages/events'
      }
    }
    serialization: {
      type: 'Json'
      properties: {
        encoding: 'UTF8'
      }
    }
  }
}

resource saOutput 'Microsoft.StreamAnalytics/streamingjobs/outputs@2021-10-01-preview' = {
  parent: saJob
  name: 'cosmosOutput'
  properties: {
    datasource: {
      type: 'Microsoft.Storage/DocumentDB'
      properties: {
        accountId: cosmosAccountName
        accountKey: listKeys(resourceId('Microsoft.DocumentDB/databaseAccounts', cosmosAccountName), '2023-11-15').primaryMasterKey
        database: cosmosDatabase
        collectionNamePattern: cosmosContainer
        partitionKey: '/deviceId'
      }
    }
  }
}

resource saEventHubOutput 'Microsoft.StreamAnalytics/streamingjobs/outputs@2021-10-01-preview' = {
  parent: saJob
  name: 'eventHubAlertOutput'
  properties: {
    datasource: {
      type: 'Microsoft.EventHub/EventHub'
      properties: {
        serviceBusNamespace: eventHubNamespace
        eventHubName: eventHubName
        sharedAccessPolicyName: eventHubPolicyName
        sharedAccessPolicyKey: eventHubPolicyKey
      }
    }
    serialization: {
      type: 'Json'
      properties: {
        encoding: 'UTF8'
      }
    }
  }
}
