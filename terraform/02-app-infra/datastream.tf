# terraform/02-app-infra/datastream.tf

# Network Attachment for PSC
resource "google_compute_network_attachment" "ds_to_sql_attachment" {
  name                  = "na-ds-to-sql"
  region                = var.region
  connection_preference = "ACCEPT_AUTOMATIC"
  subnetworks           = [data.terraform_remote_state.network.outputs.datastream_psc_subnet_self_link]
}

# Firewall rule to allow egress from PSC subnet to Cloud SQL
resource "google_compute_firewall" "allow_datastream_psc_to_sql" {
  name      = "fw-allow-ds-psc-to-sql-egress"
  network   = data.terraform_remote_state.network.outputs.vpc_self_link
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges      = [data.terraform_remote_state.network.outputs.datastream_psc_subnet_cidr]
  destination_ranges = ["${google_sql_database_instance.mysql_instance.private_ip_address}/32"]
}

# Datastream Private Connection using PSC
resource "google_datastream_private_connection" "default" {
  display_name          = var.private_connection_name
  location              = var.region
  private_connection_id = var.private_connection_name

  psc_interface_config {
    network_attachment = google_compute_network_attachment.ds_to_sql_attachment.id
  }
  depends_on = [
    google_compute_firewall.allow_datastream_psc_to_sql,
    google_project_service.project_services["datastream.googleapis.com"]
  ]
}

# Datastream Connection Profile
resource "google_datastream_connection_profile" "mysql_source_profile" {
  display_name          = var.connection_profile_name
  location              = var.region
  connection_profile_id = var.connection_profile_name

  mysql_profile {
    hostname = google_sql_database_instance.mysql_instance.private_ip_address
    port     = 3306
    username = google_sql_user.datastream_user.name
    password = random_password.ds_password.result
  }

  private_connectivity {
    private_connection = google_datastream_private_connection.default.id
  }
  depends_on = [google_datastream_private_connection.default]
}

# Datastream Connection Profile for BigQuery Destination
resource "google_datastream_connection_profile" "bigquery_destination_profile" {
  display_name          = var.bigquery_connection_profile_name
  location              = var.region
  connection_profile_id = var.bigquery_connection_profile_name
  project               = var.project_id

  bigquery_profile {}

  depends_on = [google_project_service.project_services["bigquery.googleapis.com"]]
}

# Datastream Stream
resource "google_datastream_stream" "default_stream" {
  display_name = var.stream_name
  stream_id    = var.stream_name
  location     = var.region
  project      = var.project_id

  source_config {
    source_connection_profile = google_datastream_connection_profile.mysql_source_profile.id
    mysql_source_config {
      gtid {}
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.bigquery_destination_profile.id
    bigquery_destination_config {
      data_freshness = "900s" # 15 minutes

      source_hierarchy_datasets {
        dataset_template {
          location          = var.bigquery_dataset_location
          dataset_id_prefix = "${google_bigquery_dataset.datastream_destination_dataset.dataset_id}_"
        }
      }
    }
  }

  backfill_all {}

  depends_on = [
    google_datastream_connection_profile.mysql_source_profile,
    google_datastream_connection_profile.bigquery_destination_profile
  ]
}
