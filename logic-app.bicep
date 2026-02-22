param logic_app_name string

param event_hub_name string

param event_hub_conn_name string
param outlook_conn_name string

var eventhubConnId = resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Web/connections', event_hub_conn_name)
var outlookConnId = resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Web/connections', outlook_conn_name)

var eventHubsApiId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/eastus/managedApis/eventhubs'
var outlookApiId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/eastus/managedApis/outlook'


resource logic_app_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: logic_app_name
  location: 'eastus'
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'Quando_gli_eventi_sono_disponibili_nell\'Hub_eventi': {
          recurrence: {
            interval: 3
            frequency: 'Minute'
          }
          evaluatedRecurrence: {
            interval: 3
            frequency: 'Minute'
          }
          splitOn: '@triggerBody()'
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'eventhubs\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/@{encodeURIComponent(\'${event_hub_name}\')}/events/batch/head'
            queries: {
              contentType: 'application/json'
              consumerGroupName: '$Default'
              maximumEventsCount: 50
            }
          }
        }
      }
      actions: {
        'Invia_un_messaggio_di_posta_elettronica_(v2)': {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'outlook\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: {
              To: 'g.depierro@studenti.unisa.it'
              Subject: 'Alert Ambientale'
              Body: '<p class="editor-paragraph">Device: @{triggerBody()?[\'ContentData\']?[\'deviceId\']}<br>Temperature: @{triggerBody()?[\'ContentData\']?[\'temperature\']}<br>Humidity: @{triggerBody()?[\'ContentData\']?[\'humidity\']}<br>Timestamp: @{triggerBody()?[\'ContentData\']?[\'timestamp\']}<br>Alert: @{concat(\n    if(equals(triggerBody()?[\'ContentData\']?[\'isHot\'],1),\'HOT; \',\'\'),\n    if(equals(triggerBody()?[\'ContentData\']?[\'isCold\'],1),\'COLD; \',\'\'),\n    if(equals(triggerBody()?[\'ContentData\']?[\'isDry\'],1),\'DRY; \',\'\'),\n    if(equals(triggerBody()?[\'ContentData\']?[\'isHumid\'],1),\'HUMID; \',\'\')\n)}</p><br>'
              Importance: 'Normal'
            }
            path: '/v2/Mail'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          eventhubs: {
            id: eventHubsApiId
            connectionId: eventhubConnId
            connectionName: event_hub_conn_name
            connectionProperties: {}
          }
          outlook: {
            id: outlookApiId
            connectionId: outlookConnId
            connectionName: outlook_conn_name
            connectionProperties: {}
          }
        }
      }
    }
  }
}
