# Azure Kubernetes Service Module

This module is responsible for the deployment of Azure Kubernetes Service inside a given environment. The module is developed in its own repository [here](https://github.com/jcorioland/terraform-azure-ref-aks-module).

The [environmnent-base](../environment-base/README.md) deployment has to be run before this one.

# Usage

Create a service principal for Azure Kubernetes Service, following [this documentation](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal).

Export service principal client id and client secret into Terraform environment variables:

```bash
export TF_VAR_service_principal_client_id=SP_CLIENT_ID
export TF_VAR_service_principal_client_secret=SP_CLIENT_SECRET
```

Then run the following script to deploy in the `deployment environment`.

```bash
# init terraform and backend storage
./init.sh

$ENVIRONMNENT_NAME=development
$LOCATION=westeurope

terraform apply -var env=$ENVIRONMNENT_NAME -var location=$LOCATION -var kubernetes_version="1.13.5"
```