# main.tf for gcp-datastream-cdc-data-pipeline

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# --- 1. VPC Network ---
# A VPC is not created here; we use an existing one specified by var.vpc_name.
data "google_compute_network" "main_vpc" {
  name    = var.vpc_name
  project = var.project_id
}

# --- 2. Cloud SQL for MySQL (Producer side of PSC) ---

# Enable required APIs
resource "google_project_service" "project_services" {
  for_each = toset([
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "datastream.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = true
}

# Private IP allocation for the SQL instance
# resource "google_compute_global_address" "private_ip_address" {
#   name          = "${var.db_instance_name}-private-ip"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   prefix_length = 16
#   network       = data.google_compute_network.main_vpc.id
# }

# VPC Peering connection for the SQL instance
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.main_vpc.id
  service                 = "servicenetworking.googleapis.com"
  # reserved_peering_ranges = concat(var.existing_peering_ranges, [google_compute_global_address.private_ip_address.name])
  reserved_peering_ranges = var.existing_peering_ranges
  depends_on              = [google_project_service.project_services["servicenetworking.googleapis.com"]]
}

# Random password for the datastream user
resource "random_password" "ds_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}
resource "random_password" "root_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}
resource "random_password" "admin_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

# Cloud SQL for MySQL instance
resource "google_sql_database_instance" "mysql_instance" {
  name             = var.db_instance_name
  database_version = "MYSQL_8_0"
  region           = var.region
  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.project_services["sqladmin.googleapis.com"]
  ]

  settings {
    tier = "db-n1-standard-2"
    backup_configuration {
      enabled            = true
      binary_log_enabled = true
    }
    ip_configuration {
      ipv4_enabled    = true
      private_network = data.google_compute_network.main_vpc.id
      psc_config {
        psc_enabled               = true
        allowed_consumer_projects = var.allowed_psc_projects
      }
    }
    database_flags {
      name  = "binlog_row_image"
      value = "full"
    }
    database_flags {
      name  = "max_allowed_packet"
      value = "1073741824" # 1GB
    }
    database_flags {
      name  = "net_read_timeout"
      value = "3600"
    }
    database_flags {
      name  = "net_write_timeout"
      value = "3600"
    }
    database_flags {
      name  = "wait_timeout"
      value = "86400"
    }
    availability_type = "ZONAL"
    disk_autoresize   = true
    disk_size         = 20
  }
  deletion_protection = false
}

# SQL User for Datastream
resource "google_sql_user" "datastream_user" {
  name     = "datastream"
  host     = "%"
  instance = google_sql_database_instance.mysql_instance.name
  password = random_password.ds_password.result
}
resource "google_sql_user" "root_user" {
  name     = "root"
  host     = "%"
  instance = google_sql_database_instance.mysql_instance.name
  password = random_password.root_password.result
}
resource "google_sql_user" "admin_user" {
  name     = "admin"
  host     = "%"
  instance = google_sql_database_instance.mysql_instance.name
  password = random_password.admin_password.result
}

# --- 3. Datastream Connectivity (Consumer side of PSC) ---

# Dedicated subnet for the Network Attachment
resource "google_compute_subnetwork" "datastream_psc_subnet" {
  name          = "snet-for-datastream-psc"
  ip_cidr_range = var.psc_subnet_cidr_range
  network       = data.google_compute_network.main_vpc.id
  region        = var.region
}

# Network Attachment for PSC
resource "google_compute_network_attachment" "ds_to_sql_attachment" {
  name                  = "na-ds-to-sql"
  region                = var.region
  connection_preference = "ACCEPT_AUTOMATIC"
  subnetworks           = [google_compute_subnetwork.datastream_psc_subnet.self_link]
}

# Firewall rule to allow egress from PSC subnet to Cloud SQL
resource "google_compute_firewall" "allow_datastream_psc_to_sql" {
  name      = "fw-allow-ds-psc-to-sql-egress"
  network   = data.google_compute_network.main_vpc.self_link
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges      = [google_compute_subnetwork.datastream_psc_subnet.ip_cidr_range]
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
