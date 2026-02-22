#!/usr/bin/env bash

RESOURCE_GROUP_NAME="gruppo-risorse-ambientale"

az group delete \
    --name $RESOURCE_GROUP_NAME \
    --yes
