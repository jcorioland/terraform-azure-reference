#!/bin/bash

set -e

ENVIRONMENT_NAME=$1

. ../../scripts/init-env-vars.sh

terraform init -backend-config="storage_account_name=$TF_STATE_STORAGE_ACCOUNT_NAME" \
    -backend-config="container_name=$TF_STATE_CONTAINER_NAME" \
    -backend-config="access_key=$(az keyvault secret show --name tfstate-storage-key --vault-name $KEYVAULT_NAME --query value -o tsv)" \
    -backend-config="key=$ENVIRONMENT_NAME.aks.tfstate"