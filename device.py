import sys
import json
import random
import time
from datetime import datetime, timezone
from azure.iot.device import IoTHubDeviceClient, Message

CONNECTION_STRINGS = [

]

DEVICE_CONFIGS = [
    {"id": "Store-Unit", "t_range": (20, 24), "h_range": (35, 55)},
    {"id": "Office-Room",  "t_range": (20, 24), "h_range": (35, 55)},
    {"id": "Server-Room",  "t_range": (20, 24), "h_range": (35, 55)},
    {"id": "Greenhouse",   "t_range": (20, 24), "h_range": (35, 55)},
    {"id": "Industrial",   "t_range": (20, 24), "h_range": (35, 55)}
]

DEVICE_CONFIGS_ANOMALY = [
    {"id": "Store-Unit", "t_range": (15, 17), "h_range": (26, 29)},  #COLD, DRY
    {"id": "Office-Room",  "t_range": (20, 23), "h_range": (25, 28)}, #DRY
    {"id": "Server-Room",  "t_range": (27, 30), "h_range": (32, 45)}, #HOT
    {"id": "Greenhouse",   "t_range": (27, 29), "h_range": (61, 63)}, #HOT, HUMID
    {"id": "Industrial",   "t_range": (13, 16), "h_range": (62, 65)}   #COLD, HUMID
]

clients = []
for conn in CONNECTION_STRINGS:
    clients.append(IoTHubDeviceClient.create_from_connection_string(conn))

for i in range(4):
    for i in range(len(clients)):
        config = DEVICE_CONFIGS[i]
        client = clients[i]

        temp = round(random.uniform(config["t_range"][0], config["t_range"][1]), 2)
        hum = round(random.uniform(config["h_range"][0], config["h_range"][1]), 2)
        timestamp = datetime.now(timezone.utc).isoformat()

        data = {
            "deviceId": config["id"],
            "temperature": temp,
            "humidity": hum,
            "timestamp": timestamp
        }

        msg = Message(json.dumps(data))
        client.send_message(msg)
        
        print(f"[{config['id']}] Inviato: Temp={temp}°C, Hum={hum}%")
        
        time.sleep(1)

    print("-" * 30)
    time.sleep(1)

# anomaly

for i in range(2):
    for i in range(len(clients)):
        config = DEVICE_CONFIGS_ANOMALY[i]
        client = clients[i]

        temp = round(random.uniform(config["t_range"][0], config["t_range"][1]), 2)
        hum = round(random.uniform(config["h_range"][0], config["h_range"][1]), 2)
        timestamp = datetime.now(timezone.utc).isoformat()

        data = {
            "deviceId": config["id"],
            "temperature": temp,
            "humidity": hum,
            "timestamp": timestamp
        }

        msg = Message(json.dumps(data))
        client.send_message(msg)
        
        print(f"[{config['id']}] Inviato: Temp={temp}°C, Hum={hum}%")
        
        time.sleep(1)

    print("-" * 30)
    time.sleep(1)

for i in range(4):
    for i in range(len(clients)):
        config = DEVICE_CONFIGS[i]
        client = clients[i]

        temp = round(random.uniform(config["t_range"][0], config["t_range"][1]), 2)
        hum = round(random.uniform(config["h_range"][0], config["h_range"][1]), 2)
        timestamp = datetime.now(timezone.utc).isoformat()

        data = {
            "deviceId": config["id"],
            "temperature": temp,
            "humidity": hum,
            "timestamp": timestamp
        }

        msg = Message(json.dumps(data))
        client.send_message(msg)
        
        print(f"[{config['id']}] Inviato: Temp={temp}°C, Hum={hum}%")
        
        time.sleep(1)

    print("-" * 30)
    time.sleep(1)
    
for client in clients:
    client.shutdown()