#!/usr/bin/env bash

# Importa le variabili dal file di configurazione
source ./variabili.sh

# Controllo se il file esiste
if [ ! -f ./variabili.sh ]; then
    echo "Errore: variabili.sh non trovato!"
    exit 1
fi

# Creazione resource group
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location $LOCATION_EASTUS

# Deployment IoT Hub
az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --template-file iot-hub.bicep \
  --parameters \
    iotHubName="$IOT_HUB_NAME" \
    location="$LOCATION_EASTUS"

# Deployment Cosmos DB
az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --template-file cosmos-db.bicep \
  --parameters \
    cosmos_db_account_name=$COSMOS_DB_ACCOUNT_NAME \
    location="$LOCATION_SPAIN_CENTRAL" \
    databaseName=$COSMOS_DB_NAME \
    containerName=$COSMOS_DB_CONTAINER

# Deployment Event Hub
az deployment group create \
    --resource-group $RESOURCE_GROUP_NAME \
    --template-file event-hub.bicep \
    --parameters \
        namespace_name="$EVENT_HUB_NAMESPACE" \
        location="$LOCATION_EASTUS"

NAMESPACE_CS=$(az eventhubs namespace authorization-rule keys list \
  --resource-group $RESOURCE_GROUP_NAME \
  --namespace-name $EVENT_HUB_NAMESPACE \
  --name RootManageSharedAccessKey \
  --query primaryConnectionString \
  -o tsv)

# Deployment EventHub Connection
az deployment group create \
    --resource-group $RESOURCE_GROUP_NAME \
    --template-file "eventhub-connection.bicep" \
    --parameters eventHubNamespaceConnectionString="$NAMESPACE_CS"

# Deployment Outlook Connection
az deployment group create \
    --resource-group $RESOURCE_GROUP_NAME \
    --template-file "outlook-connection.bicep"

# Deployment Logic App
az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "logic-app.bicep" \
    --parameters \
        event_hub_name="$EVENT_HUB_NAME" \
        logic_app_name="$LOGIC_APP_NAME" \
        event_hub_conn_name="$EVENT_HUB_CONN_NAME" \
        outlook_conn_name="$OUTLOOK_CONN_NAME"

# Ottengo chiave primaria iot hub per Stream Analytics
SA_KEY=$(az iot hub policy show \
    --hub-name "$IOT_HUB_NAME" \
    --name "service" \
    --query primaryKey -o tsv)

# Ottengo chiave primaria event hub per Stream Analytics
EH_KEY=$(az eventhubs eventhub authorization-rule keys list \
  --resource-group $RESOURCE_GROUP_NAME \
  --namespace-name $EVENT_HUB_NAMESPACE \
  --eventhub-name $EVENT_HUB_NAME \
  --name "IoTStreamJobPolicy" \
  --query primaryKey -o tsv)

# Deployment Stream Analytics Job
az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --template-file stream-analytics.bicep \
  --parameters \
    streamAnalyticsJobName="$STREAM_ANALYTICS_JOB_NAME" \
    location="$LOCATION_EASTUS" \
    iotHubName="$IOT_HUB_NAME" \
    sharedAccessPolicyKey=$SA_KEY \
    cosmosAccountName=$COSMOS_DB_ACCOUNT_NAME \
    cosmosDatabase=$COSMOS_DB_NAME \
    cosmosContainer=$COSMOS_DB_CONTAINER \
    eventHubNamespace="$EVENT_HUB_NAMESPACE" \
    eventHubName="$EVENT_HUB_NAME" \
    eventHubPolicyName="IoTStreamJobPolicy" \
    eventHubPolicyKey=$EH_KEY

# Avvio dello Stream Analytics Job
az stream-analytics job start  \
    --name "$STREAM_ANALYTICS_JOB_NAME" \
    --resource-group $RESOURCE_GROUP_NAME

# Creazione device
az iot hub device-identity create --hub-name "$IOT_HUB_NAME" --device-id "device1"
az iot hub device-identity create --hub-name "$IOT_HUB_NAME" --device-id "device2"
az iot hub device-identity create --hub-name "$IOT_HUB_NAME" --device-id "device3"
az iot hub device-identity create --hub-name "$IOT_HUB_NAME" --device-id "device4"
az iot hub device-identity create --hub-name "$IOT_HUB_NAME" --device-id "device5"

# Ricavo connection string
conn1=$(az iot hub device-identity connection-string show --hub-name "$IOT_HUB_NAME" --device-id "device1" --output tsv)
conn2=$(az iot hub device-identity connection-string show --hub-name "$IOT_HUB_NAME" --device-id "device2" --output tsv)
conn3=$(az iot hub device-identity connection-string show --hub-name "$IOT_HUB_NAME" --device-id "device3" --output tsv)
conn4=$(az iot hub device-identity connection-string show --hub-name "$IOT_HUB_NAME" --device-id "device4" --output tsv)
conn5=$(az iot hub device-identity connection-string show --hub-name "$IOT_HUB_NAME" --device-id "device5" --output tsv)

# Prendo Connection String di Cosmos per SWA
CONN_STR=$(az cosmosdb keys list --name $COSMOS_DB_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME --type connection-strings --query "connectionStrings[0].connectionString" -o tsv)

# Creo la Static Web App  
az deployment group create \
    --resource-group $RESOURCE_GROUP_NAME \
    --template-file swa-dashboard.bicep \
    --parameters \
        swa_dashboard_name="$SWA_NAME" \
        cosmos_connection_string="$CONN_STR" \
        db_name="$COSMOS_DB_NAME" \
        container_name="$COSMOS_DB_CONTAINER" \
        repo_url="$REPO_URL" \
        github_token="$GITHUB_TOKEN"



# --- SEZIONE MONITORAGGIO ---

# 1. Creazione Log Analytics Workspace (il magazzino dei log)
az monitor log-analytics workspace create \
    --resource-group $RESOURCE_GROUP_NAME \
    --workspace-name "Workspace-IoT-Aziendale" \
    --location $LOCATION_EASTUS

# Recupero l'ID del workspace appena creato
WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --resource-group $RESOURCE_GROUP_NAME \
    --workspace-name "Workspace-IoT-Aziendale" \
    --query id -o tsv)

# 2. Creazione Application Insights collegato al workspace
az monitor app-insights component create \
    --app "Insights-IoT-Pipeline" \
    --location $LOCATION_EASTUS \
    --resource-group $RESOURCE_GROUP_NAME \
    --workspace "Workspace-IoT-Aziendale" \
    --kind web \
    --application-type web



# --- ATTIVAZIONE DIAGNOSTICA ---

# Recupero l'ID dell'IoT Hub e del Job di Stream Analytics
IOT_HUB_ID=$(az iot hub show --name "$IOT_HUB_NAME" --resource-group $RESOURCE_GROUP_NAME --query id -o tsv)
SA_JOB_ID=$(az stream-analytics job show --name "$STREAM_ANALYTICS_JOB_NAME" --resource-group $RESOURCE_GROUP_NAME --query id -o tsv)

# Attivo i log per IoT Hub (Connessioni e Telemetria)
az monitor diagnostic-settings create \
    --name "diag-iothub" \
    --resource $IOT_HUB_ID \
    --workspace $WORKSPACE_ID \
    --logs '[{"category": "Connections", "enabled": true}, {"category": "DeviceTelemetry", "enabled": true}]'

# Attivo i log per Stream Analytics (Errori di esecuzione e output)
az monitor diagnostic-settings create \
    --name "diag-stream" \
    --resource $SA_JOB_ID \
    --workspace $WORKSPACE_ID \
    --logs '[{"category": "Execution", "enabled": true}, {"category": "Authoring", "enabled": true}]' \
    --metrics '[{"category": "AllMetrics", "enabled": true}]'

echo "\"$conn1\","
echo "\"$conn2\","
echo "\"$conn3\","
echo "\"$conn4\","
echo "\"$conn5\""