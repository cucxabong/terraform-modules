locals {
  vpc_name                  = var.cluster_name
  location                  = var.regional ? var.region : var.zone
  default_node_locations    = var.regional ? data.google_compute_zones.azs[0].names : [var.zone]
  node_locations            = length(var.node_zones) > 0 ? var.node_zones : local.default_node_locations
  enable_logging_components = var.disable_workload_log ? ["SYSTEM_COMPONENTS"] : ["SYSTEM_COMPONENTS", "WORKLOADS"]

  node_pool_names = [for np in toset(var.node_pools) : np.name]
  node_pools      = zipmap(local.node_pool_names, tolist(toset(var.node_pools)))
  ip_allocation_policy = var.networking_mode == "VPC_NATIVE" ? [{
    cluster_ipv4_cidr_block  = var.ip_range_pods
    services_ipv4_cidr_block = var.ip_range_services
  }] : []
}
