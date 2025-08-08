# --- BigQuery Destination ---

# BigQuery Dataset for Datastream destination
resource "google_bigquery_dataset" "datastream_destination_dataset" {
  dataset_id = var.bigquery_dataset_name
  location   = var.bigquery_dataset_location
  project    = var.project_id
}
