# Enable required APIs for the project
resource "google_project_service" "project_services" {
  for_each = toset([
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "datastream.googleapis.com",
    "bigquery.googleapis.com",
    "compute.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}
