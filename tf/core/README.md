# Core Module

This module is responsible for the deployment for all the core components and resources for a given environment, like:

- The resource group
- The virtual network and subnets
- The peerings

# Usage

```bash
# init terraform and backend storage
./init.sh

$ENVIRONMNENT_NAME=development
$LOCATION=westeurope

terraform plan -out "core.plan" -var env=$ENVIRONMNENT_NAME -var location=$LOCATION
terraform apply "core.plan"
```