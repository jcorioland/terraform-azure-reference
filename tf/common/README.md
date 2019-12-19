# Common Module

This modules is responsible for deploying the common stuff required for the reference archicture for Terraform on Azure.The module is developed in its own repository [here](https://github.com/jcorioland/terraform-azure-ref-common-module).


# Usage

Fill environment variables and run script:

```bash
export TF_VAR_location="francecentral"
export TF_VAR_tenant_id="<YOUR_TENANT_ID>"

# init terraform and backend storage
./init.sh

terraform apply -auto-approve
```