# variables.tf for gcp-datastream-cdc-data-pipeline

variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be created."
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "The name of the existing VPC network to use."
  type        = string
  default     = "default"
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

variable "psc_subnet_cidr_range" {
  description = "A free CIDR range of /29 for the Datastream PSC subnet (e.g., 10.3.0.0/29). Must not overlap with other subnets."
  type        = string
}

variable "private_connection_name" {
  description = "The name for the Datastream private connection."
  type        = string
  default     = "mysql-private-connection-psc"
}

variable "connection_profile_name" {
  description = "The name of the connection profile."
  type        = string
  default     = "mysql-connection-profile-psc"
}

variable "existing_peering_ranges" {
  description = "A list of existing peering ranges to preserve in the service networking connection."
  type        = list(string)
  default     = []
}
