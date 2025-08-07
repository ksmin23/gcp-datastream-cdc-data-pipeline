# outputs.tf for gcp-datastream-cdc-data-pipeline

output "cloud_sql_instance_name" {
  description = "The name of the created Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.name
}

output "cloud_sql_private_ip_address" {
  description = "The private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.private_ip_address
}

output "cloud_sql_public_ip_address" {
  description = "The public IP address of the Cloud SQL instance. Note: This may be empty if not configured."
  value       = google_sql_database_instance.mysql_instance.public_ip_address
}

output "datastream_user_name" {
  description = "The username for the Datastream database user."
  value       = google_sql_user.datastream_user.name
}

output "datastream_user_password" {
  description = "The password for the Datastream user. Use `terraform output -json | jq -r .datastream_user_password.value` to view."
  value       = random_password.ds_password.result
  sensitive   = true
}

output "datastream_connection_profile_name" {
  description = "The name of the Datastream connection profile created."
  value       = google_datastream_connection_profile.mysql_source_profile.name
}

output "datastream_private_connection_name" {
  description = "The name of the Datastream private connection resource."
  value       = google_datastream_private_connection.default.name
}

output "datastream_bigquery_connection_profile_name" {
  description = "The name of the Datastream BigQuery destination connection profile created."
  value       = google_datastream_connection_profile.bigquery_destination_profile.name
}

output "root_user_name" {
  description = "The username for the root database user."
  value       = google_sql_user.root_user.name
}

output "root_user_password" {
  description = "The password for the root user. Use `terraform output -json | jq -r .root_user_password.value` to view."
  value       = random_password.root_password.result
  sensitive   = true
}

output "admin_user_name" {
  description = "The username for the admin database user."
  value       = google_sql_user.admin_user.name
}

output "admin_user_password" {
  description = "The password for the admin user. Use `terraform output -json | jq -r .admin_user_password.value` to view."
  value       = random_password.admin_password.result
  sensitive   = true
}

output "datastream_stream_name" {
  description = "The name of the Datastream stream created."
  value       = google_datastream_stream.default_stream.name
}
