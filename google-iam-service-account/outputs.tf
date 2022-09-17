output "google_service_account_email" {
  value = google_service_account.gcp_service_account.email
}

output "google_service_account_id" {
  value = google_service_account.gcp_service_account.name
}
