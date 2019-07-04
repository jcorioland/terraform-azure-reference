output "resource_group_name" {
  value = "${azurerm_resource_group.rg.name}"
}

output "location" {
  value = "${var.location}"
}

output "environment" {
  value = "${var.environment}"
}
