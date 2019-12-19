output "resource_group_name" {
  value = module.aks.resource_group_name
}

output "aks_client_key" {
  value = module.aks.aks_client_key
}

output "aks_client_certificate" {
  value = module.aks.aks_client_certificate
}

output "aks_cluster_ca_certificate" {
  value = module.aks.aks_cluster_ca_certificate
}

output "aks_cluster_username" {
  value = module.aks.aks_cluster_username
}

output "aks_cluster_password" {
  value = module.aks.aks_cluster_password
}

output "aks_kube_config" {
  value = module.aks.aks_kube_config
}

output "aks_host" {
  value = module.aks.aks_host
}