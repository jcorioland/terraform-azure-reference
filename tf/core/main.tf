provider "azurerm" {
  version = "~> 1.39"
}

terraform {
  backend "azurerm" {
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "tf-ref-${var.environment}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "aks" {
  name                = "aks-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefix       = "10.1.0.0/24"
}

resource "azurerm_virtual_network" "backend" {
  name                = "backend-vnet"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "backend" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.backend.name
  address_prefix       = "10.2.0.0/24"
}

resource "azurerm_virtual_network_peering" "peering1" {
  name                      = "aks2backend"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.aks.name
  remote_virtual_network_id = azurerm_virtual_network.backend.id
}

resource "azurerm_virtual_network_peering" "peering2" {
  name                      = "backend2aks"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.backend.name
  remote_virtual_network_id = azurerm_virtual_network.aks.id
}

