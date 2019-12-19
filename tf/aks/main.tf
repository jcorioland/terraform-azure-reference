terraform {
  backend "azurerm" {
  }
}

module "aks" {
  source                          = "git@github.com:jcorioland/terraform-azure-ref-aks-module"
  environment                     = var.environment
  location                        = var.location
  kubernetes_version              = var.kubernetes_version
  service_principal_client_id     = var.service_principal_client_id
  service_principal_client_secret = var.service_principal_client_secret
  ssh_public_key                  = var.ssh_public_key
}

