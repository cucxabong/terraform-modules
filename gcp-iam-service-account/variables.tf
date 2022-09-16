variable "gcp_service_account_name" {
  type = string
}

variable "kubernetes_namespace" {
  type = string
}

variable "kubernetes_service_account_name" {
  default = ""
}

variable "gcp_roles" {
  default = []
}

variable "disable_workload_identity" {
  default = false
}

variable "create_sa_key" {
  default = false
}

variable "export_sa_private_key" {
  default = false
}

variable "project" {
  type = string
}
