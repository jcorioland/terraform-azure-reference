# Terraform on Azure Reference Architecture

This repository helps you to implement Infrastructure as Code best practices using Terraform and Microsoft Azure.

If you are not familiar with Infrastructure as Code (IaC), read [this page](https://docs.microsoft.com/en-us/azure/devops/learn/what-is-infrastructure-as-code) first.

## Overview of the architecture

*Note: in this example we don't pay attention as the application that is deployed itself as the focus is on deploying the infrastructure.*

This repository guides you in deploying the following architecture on Microsoft Azure, using [Terraform](https://www.terraform.io/intro/index.html).

![Sample Architecture](assets/architecture.jpg)

There are 3 environments (Dev, QA and Prod). Each of the environment contains:
- An [Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/intro-kubernetes) cluster, in its own virtual network
- Some load balancers
- A backend virtual network, that contains a [Virtual Machine Scale Set](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/overview) hosting a "legacy application"
- An [Azure Database for MySQL](https://docs.microsoft.com/en-us/azure/mysql/overview) service instance with [virtual network service endpoint](https://docs.microsoft.com/en-us/azure/mysql/concepts-data-access-and-security-vnet) so it can be reached by the legacy workloads and services running in AKS (Backend virtual network and AKS virtual network are peered together)

There are also common services used here:
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/), to store the Docker image
- [Azure KeyVault](https://docs.microsoft.com/en-us/azure/key-vault/), to store the application secrets securely
- [Azure Firewall](https://docs.microsoft.com/en-us/azure/firewall/), to protect the application

We will also use [Azure Monitor](https://docs.microsoft.com/en-us/azure/azure-monitor/) with logs analytics to monitor all this infrastructure (and potentially the application).

Finally, all the infrastructure will be describe using Terraform HCL manifests stored in GitHub (this repository) and we will use [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/overview?view=azure-devops) to deploy all the infrastructure.

*Note: technically speaking, the pipeline that automates Terraform deployment can be hosted in any other CI/CD tool, like Jenkins, for example.*

As you can see, some parts of the infrastructure are specific for each environment, some other will be shared. This will help to illustrate how to handle deployments of different resources having different lifecycle.

## Prerequisites

In order to follow this documentation and try it by yourself, you need:

- A Microsoft Azure account. You can create a free trial account [here](https://azure.microsoft.com/en-us/free/).
- [Install Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) on your machine, if you want to experiment the scripts locally
- Fork this repository into your GitHub account
- An Azure DevOps organization. You can get started for free [here](https://azure.microsoft.com/en-us/services/devops/?nav=min) if you do not already use Azure DevOps
- Install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

If you are not familiar with Terraform yet, we strongly recommend that you follow the Terraform on Azure getting started guide on [this page](https://learn.hashicorp.com/terraform/azure/intro_az).

## Terraform State

Terraform needs to maintain state between the deployments, to make sure to what needs to be added or removed.

Storing Terraform state remotely is a best practice to make sure you don't loose it across your different execution environment (from your machine to any CI/CD agent). It is possible to use Azure Storage as a remote backend for Terraform state.

To initialize the the Azure Storage backend, you can execute the [scripts/init-remote-state-backend.sh](scripts/init-remote-state-backend.sh):

```bash
#!/bin/bash

set -e

. ./init-env-vars.sh

# Create the resource group
echo "Creating $COMMON_RESOURCE_GROUP_NAME resource group..."
az group create -n $COMMON_RESOURCE_GROUP_NAME -l $LOCATION

echo "Resource group $COMMON_RESOURCE_GROUP_NAME created."

# Create the storage account
echo "Creating $TF_STATE_STORAGE_ACCOUNT_NAME storage account..."
az storage account create -g $COMMON_RESOURCE_GROUP_NAME -l $LOCATION \
  --name $TF_STATE_STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob

echo "Storage account $TF_STATE_STORAGE_ACCOUNT_NAME created."

# Retrieve the storage account key
echo "Retrieving storage account key..."
ACCOUNT_KEY=$(az storage account keys list --resource-group $COMMON_RESOURCE_GROUP_NAME --account-name $TF_STATE_STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

echo "Storage account key retrieved."

# Create a storage container (for the Terraform State)
echo "Creating $TF_STATE_CONTAINER_NAME storage container..."
az storage container create --name $TF_STATE_CONTAINER_NAME --account-name $TF_STATE_STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

echo "Storage container $TF_STATE_CONTAINER_NAME created."

# Create an Azure KeyVault
echo "Creating $KEYVAULT_NAME key vault..."
az keyvault create -g $COMMON_RESOURCE_GROUP_NAME -l $LOCATION --name $KEYVAULT_NAME

echo "Key vault $KEYVAULT_NAME created."

# Storage the Terraform State Storage Key into KeyVault
echo "Storage storage access key into key vault secret..."
az keyvault secret set --name tfstate-storage-key --value $ACCOUNT_KEY --vault-name $KEYVAULT_NAME

echo "Key vault secret created."

# Display information
echo "Azure Storage Account and KeyVault have been created."
echo "Run the following command to initialize Terraform to store its state into Azure Storage:"
echo "terraform init -backend-config=\"storage_account_name=$TF_STATE_STORAGE_ACCOUNT_NAME\" -backend-config=\"container_name=$TF_STATE_CONTAINER_NAME\" -backend-config=\"access_key=\$(az keyvault secret show --name tfstate-storage-key --vault-name $KEYVAULT_NAME --query value -o tsv)\" -backend-config=\"key=terraform-ref-architecture-tfstate\""
```

This script is responsible for:
- Creating an Azure Resource Group
- Creating an Azure Storage Account
- Retrieving the Storage Account access key
- Creating a container in the Storage Account (where the Terraform state will be stored)
- Creating an Azure Key Vault
- Storing the the Storage Account access key into a Key Vault secret named `tfstate-storage-key`

Once completed, the script will print a the `terraform init` command line that you will use later to init Terraform to use this backend, like:

```bash
terraform init -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME" -backend-config="container_name=$CONTAINER_NAME" -backend-config="access_key=$(az keyvault secret show --name tfstate-storage-key --vault-name $KEYVAULT_NAME --query value -o tsv)" -backend-config="key=terraform-ref-architecture-tfstate"
```

*Note: If you are working with multiple cloud providers, you may not want to spare storage state into each provider. For this reason, you may want to look the [Terraform Cloud remote state management](https://www.hashicorp.com/blog/introducing-terraform-cloud-remote-state-management) that has been introduced by HashiCorp.*

## Terraform modules

### What are Terraform modules?

[Terraform modules](https://www.terraform.io/docs/modules/index.html) are used to group together a set of resources that have the same lifecycle. It is not mandatory to use modules, but in some case it might be useful.

Like all mechanisms that allow to mutualize/factorize code, modules can also be dangerous: you don't want to have a big module that contains everything that you need to deploy and make all the resources strongly coupled together. This could lead to a monolith that will be really hard to maintain and to deploy.

Here are some questions that you can ask yourself for before writing a module:
- Do have all the resources involved the same lifecycle?
  - Will the resources be deployed all together all the time?
  - Will the resources be updated all together all the time?
  - Will the resources be destroyed all together all the time?
- Is there multiple resources involved? If there is just one, the module is probably useless
- From an architectural/functionnal perspective, does it makes sense to group all these resources together? (network, compute, storage etc...)
- Does any of the resource involved depend from a resource that is not in this module?

If the answer to these questions is `no` most of the time, then you probably don't need to write a module.

Sometime, instead of writing a big module, it can be useful to write multiple ones and nest them together, depending on the scenario you want to cover.

You can read more about Terraform modules on [this page of the Terraform documentation](https://www.terraform.io/docs/modules/index.html).

### How to test Terraform modules?

Like every piece of code, Terraform modules can be tested. [Terratest](https://github.com/gruntwork-io/terratest) is the tool I have used to write the test of the modules available in this repository.

You can find more documentation about how to use Terratest to test Terraform modules developed for Azure [here](https://docs.microsoft.com/en-us/azure/terraform/terratest-in-terraform-modules).

### Use Yeoman to generate your Terraform modules structure

If you want to get started quickly with writing Terraform modules you can use Yeoman with the `az-terra-module` like described on [this page](https://docs.microsoft.com/en-us/azure/terraform/terraform-vscode-module-generator).

It will generate all the structure for you, from Terraform HCL files to tests and Dockerfile.

## Modules of this reference architecture 

This reference architecture uses different Terraform module to deploy different set of components and deal with their different lifecyle:

- **TODO** Common Module: contains all the common resources like ACR, KeyVault, Monitoring...
- [Environment Base Module](tf/environment-base/README.md)
- [Azure Kubernetes Module](tf/aks/README.md)
- **TODO** Legacy ScaleSet Module: contains the TF script to deploy the legacy scale set into an environment
- **TODO** PostgreSQL Module: contains the TF scripts to deploy PostgreSQL into an environment