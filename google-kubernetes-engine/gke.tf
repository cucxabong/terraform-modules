
resource "google_container_cluster" "this" {
  name               = var.cluster_name
  location           = local.location
  node_locations     = local.node_locations
  initial_node_count = var.initial_node_count
  network            = google_compute_network.this.name
  subnetwork         = google_compute_subnetwork.nodes.name

  datapath_provider = var.datapath_provider

  networking_mode = var.networking_mode

  dynamic "ip_allocation_policy" {
    for_each = local.ip_allocation_policy
    content {
      cluster_ipv4_cidr_block  = var.ip_range_pods
      services_ipv4_cidr_block = var.ip_range_services
    }
  }

  remove_default_node_pool = var.remove_default_node_pool

  logging_config {
    enable_components = local.enable_logging_components
  }

  workload_identity_config {
    workload_pool = "${data.google_client_config.this.project}.svc.id.goog"
  }

  release_channel {
    channel = var.release_channel
  }
}

resource "google_container_node_pool" "this" {
  for_each       = local.node_pools
  name           = each.key
  cluster        = google_container_cluster.this.id
  location       = local.location
  version        = data.google_container_engine_versions.this.release_channel_default_version.REGULAR
  node_locations = lookup(each.value, "node_locations", local.node_locations)
  node_count     = lookup(each.value, "autoscaling", true) ? null : lookup(each.value, "node_count", 1)
  management {
    auto_upgrade = lookup(each.value, "auto_upgrade", false)
    auto_repair  = lookup(each.value, "auto_repair", true)
  }

  dynamic "autoscaling" {
    for_each = lookup(each.value, "autoscaling", true) ? [each.value] : []
    content {
      min_node_count = lookup(autoscaling.value, "min_count", 1)
      max_node_count = lookup(autoscaling.value, "max_count", 20)
    }
  }

  node_config {
    image_type   = lookup(each.value, "image_type", "COS_CONTAINERD")
    machine_type = lookup(each.value, "machine_type", "e2-medium")

    disk_size_gb = lookup(each.value, "disk_size_gb", 100)
    disk_type    = lookup(each.value, "disk_type", "pd-standard")

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
