# terraform/02-app-infra/outputs.tf

output "cloud_sql_instance_name" {
  description = "The name of the Cloud SQL for MySQL instance."
  value       = google_sql_database_instance.mysql_instance.name
}

output "cloud_sql_instance_private_ip" {
  description = "The private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.private_ip_address
  sensitive   = true
}

output "datastream_stream_name" {
  description = "The name of the Datastream stream."
  value       = google_datastream_stream.default_stream.name
}

output "bigquery_dataset_id" {
  description = "The ID of the BigQuery destination dataset."
  value       = google_bigquery_dataset.datastream_destination_dataset.dataset_id
}

output "datastream_user_name" {
  description = "The username for the 'datastream' SQL user."
  value       = google_sql_user.datastream_user.name
}

output "datastream_user_password" {
  description = "The password for the 'datastream' SQL user."
  value       = random_password.ds_password.result
  sensitive   = true
}

output "admin_user_name" {
  description = "The username for the database admin."
  value       = google_sql_user.admin_user.name
}

output "admin_user_password" {
  description = "The password for the database admin user."
  value       = random_password.admin_password.result
  sensitive   = true
}
