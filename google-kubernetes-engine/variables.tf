variable "cluster_name" {
  type = string
}

variable "enable_kubernetes_alpha" {
  type    = bool
  default = false
}

variable "ip_range_nodes" {
  type    = string
  default = "10.0.0.0/20"
}

variable "ip_range_services" {
  type    = string
  default = "10.0.16.0/20"
}

variable "ip_range_pods" {
  type    = string
  default = "10.128.0.0/16"
}

variable "networking_mode" {
  type    = string
  default = "ROUTES"
}

variable "regional" {
  default = false
  type    = bool
}

variable "region" {
  default = ""
  type    = string
}

variable "zone" {
  default = ""
  type    = string
}

variable "initial_node_count" {
  type    = number
  default = 1
}

variable "release_channel" {
  default = "UNSPECIFIED"
  type    = string
  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Valid values for release_channel are UNSPECIFIED/RAPID/REGULAR/STABLE"
  }
}

variable "node_zones" {
  type    = list(string)
  default = []
}

variable "remove_default_node_pool" {
  default     = false
  type        = bool
  description = "Remove default node pool while setting up the cluster"
}

variable "disable_workload_log" {
  type        = bool
  default     = false
  description = "Disable sending application logs to Google Cloud Logging Service"
}

variable "node_pools" {
  type = list(object({
    name           = string
    node_locations = optional(list(string))
    node_count     = optional(number)
    autoscaling    = optional(bool)
    min_count      = optional(number)
    max_count      = optional(number)
    image_type     = optional(string)
    machine_type   = optional(string)
    disk_size_gb   = optional(string)
    disk_type      = optional(string)
    auto_upgrade   = optional(bool)
    auto_repair    = optional(bool)
  }))
  default = []
}

variable "datapath_provider" {
  description = "The desired datapath provider for this cluster. By default, `DATAPATH_PROVIDER_UNSPECIFIED` enables the IPTables-based kube-proxy implementation. `ADVANCED_DATAPATH` enables Dataplane-V2 feature."
  default     = "DATAPATH_PROVIDER_UNSPECIFIED"
  type        = string
  validation {
    condition     = contains(["DATAPATH_PROVIDER_UNSPECIFIED", "ADVANCED_DATAPATH"], var.datapath_provider)
    error_message = "Valid values for datapath_provider are DATAPATH_PROVIDER_UNSPECIFIED/ADVANCED_DATAPATH"
  }
}

variable "csi_secrets_store" {
  default = {
    enabled = false
  }
  type = object({
    enabled                = bool
    repository             = optional(string)
    name                   = optional(string)
    chart                  = optional(string)
    namespace              = optional(string)
    version                = optional(string)
    enable_sync_secret     = optional(bool)
    enable_secret_rotation = optional(bool)
    providers = optional(object({
      gcp = optional(object({
        enabled = optional(bool)
        version = optional(string)
      }))
    }))
  })
}

variable "argocd" {
  default = {
    enabled = false
  }
  type = object({
    enabled    = bool
    repository = optional(string)
    name       = optional(string)
    chart      = optional(string)
    version    = optional(string)
    namespace  = optional(string)
    values     = optional(list(string))
  })
}

# variable "nginx_ingress" {
#   default = {
#     enabled = false
#   }
#   type = object({
#     enabled    = bool
#     repository = optional(string)
#     name       = optional(string)
#     chart      = optional(string)
#     version    = optional(string)
#     namespace  = optional(string)
#     values     = optional(list(string))
#   })
# }

# variable "external_dns" {
#   default = {
#     enabled = false
#   }
#   type = object({
#     enabled    = bool
#     repository = optional(string)
#     name       = optional(string)
#     chart      = optional(string)
#     version    = optional(string)
#     namespace  = optional(string)
#     values     = optional(list(string))
#   })
# }
