locals {
  kubernetes_service_account_name = length(var.kubernetes_service_account_name) > 0 ? var.kubernetes_service_account_name : var.gcp_service_account_name

}

data "google_project" "current" {}


resource "google_service_account" "gcp_service_account" {
  account_id   = var.gcp_service_account_name
  display_name = var.gcp_service_account_name
}

resource "google_service_account_key" "sa_key" {
  count              = var.create_sa_key ? 1 : 0
  service_account_id = google_service_account.gcp_service_account.name
}

resource "local_file" "sa_private_key_file" {
  count           = var.create_sa_key && var.export_sa_private_key ? 1 : 0
  content         = base64decode(google_service_account_key.sa_key[0].private_key)
  filename        = "${path.root}/${replace(google_service_account.gcp_service_account.email, "@", "_at_")}.json"
  file_permission = "0400"
}

resource "google_project_iam_member" "roles_binding" {
  for_each = toset(var.gcp_roles)
  role     = each.value
  project  = var.project
  member   = "serviceAccount:${google_service_account.gcp_service_account.email}"
}

resource "google_service_account_iam_binding" "pod_sa_bingding" {
  count              = var.disable_workload_identity ? 0 : 1
  service_account_id = google_service_account.gcp_service_account.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${data.google_project.current.project_id}.svc.id.goog[${var.kubernetes_namespace}/${local.kubernetes_service_account_name}]",
  ]
}
