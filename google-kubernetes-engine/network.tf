resource "google_compute_network" "this" {
  name                    = local.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "nodes" {
  name          = "${var.cluster_name}-${local.location}"
  ip_cidr_range = var.ip_range_nodes
  network       = google_compute_network.this.id
}
