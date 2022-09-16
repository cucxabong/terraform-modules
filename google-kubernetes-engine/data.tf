# Data Sources
data "google_client_config" "this" {}

data "google_compute_zones" "azs" {
  count  = var.regional ? 1 : 0
  region = var.region
}

data "google_container_engine_versions" "this" {
  location = local.location
}
