provider "azurerm" {
  version = "~>1.30"
}

terraform {
  backend "azurerm" {}
}

module "aks" {
  source             = "git@github.com:jcorioland/terraform-azure-ref-aks-module"
  environment        = "${var.environment}"
  location           = "${var.location}"
  kubernetes_version = "1.13.5"
  ssh_public_key     = "${file("~/.ssh/id_rsa.pub")}"
}