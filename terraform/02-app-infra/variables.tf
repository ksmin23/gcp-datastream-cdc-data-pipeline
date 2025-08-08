# terraform/02-app-infra/variables.tf

variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be created."
  type        = string
  default     = "us-central1"
}

variable "db_instance_name" {
  description = "The name of the Cloud SQL database instance."
  type        = string
  default     = "mysql-src-ds"
}

variable "allowed_psc_projects" {
  description = "A list of consumer projects allowed to connect via PSC. Must include your project ID."
  type        = list(string)
}

variable "private_connection_name" {
  description = "The name for the Datastream private connection."
  type        = string
  default     = "mysql-private-connection-psc"
}

variable "connection_profile_name" {
  description = "The name of the connection profile."
  type        = string
  default     = "mysql-source-connection-profile-psc"
}

variable "bigquery_dataset_name" {
  description = "The name of the BigQuery dataset to be used as the destination."
  type        = string
  default     = "datastream_destination_dataset"
}

variable "bigquery_dataset_location" {
  description = "The location for the BigQuery dataset."
  type        = string
  default     = "US"
}

variable "bigquery_connection_profile_name" {
  description = "The name for the BigQuery destination connection profile."
  type        = string
  default     = "bigquery-destination-profile"
}

variable "stream_name" {
  description = "The name for the Datastream stream."
  type        = string
  default     = "mysql-to-bigquery-stream"
}
