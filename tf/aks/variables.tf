variable "environment" {
  description = "Name of the environment"
}

variable "location" {
  description = "Azure location to use"
}

variable "kubernetes_version" {
  description = "The Kubernetes version to use"
}

variable "service_principal_client_id" {
  description = "The client id of the service principal to be used by AKS"
}

variable "service_principal_client_secret" {
  description = "The client secret of the service principal to be used by AKS"
}

variable "ssh_public_key_file" {
  description = "The SSH public key file to use with AKS"
}