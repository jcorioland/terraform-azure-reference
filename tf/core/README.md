# Core Module

This module is responsible for the deployment for all the core components and resources for a given environment, like:

- The resource group
- The virtual network and subnets
- The peerings

# Usage

```bash
ENVIRONMENT_NAME="development"
LOCATION="francecentral"

# init terraform and backend storage
./init.sh $ENVIRONMENT_NAME

terraform apply -var environment=$ENVIRONMENT_NAME -var location=$LOCATION -auto-approve
```