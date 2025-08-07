# GCP Datastream and Cloud SQL for MySQL using Private Service Connect (PSC)

This Terraform project provisions a complete end-to-end solution for capturing Change Data Capture (CDC) data from a Cloud SQL for MySQL instance using GCP Datastream. The entire connection is established securely and privately using **Private Service Connect (PSC)**, eliminating the need for VPC Peering.

## Architecture

This project creates the following architecture:

1.  **Cloud SQL for MySQL Instance**: A new MySQL 8.0 instance is provisioned with a private IP address. It is configured as the **service producer**, automatically publishing its service via a managed Service Attachment by enabling PSC.
2.  **Datastream Connectivity**:
    *   A dedicated subnet is created within your existing VPC for PSC connectivity.
    *   A **Network Attachment** is created, acting as the connection point for Datastream into your VPC.
    *   An egress firewall rule is established to allow traffic from the PSC subnet to the Cloud SQL instance's private IP on port 3306.
    *   A **Datastream Private Connection** resource is configured to use the Network Attachment, establishing the consumer side of the PSC connection.
3.  **Datastream Connection Profile**: A connection profile is created that uses the private connection to securely access the Cloud SQL instance via its private IP address.

This setup ensures that all data transfer between Datastream and Cloud SQL occurs over Google's private network, without exposing any resources to the public internet.

## Prerequisites

*   **Terraform**: `v1.5.7` or later
*   **Google Cloud SDK**: Authenticated to your GCP account (`gcloud auth application-default login`).
*   **An existing VPC Network**: This project uses a pre-existing VPC. The default is `default`.

## How to Use

1.  **Clone the repository and navigate to this directory.**

2.  **Configure `terraform.tfvars`**:
    Create a `terraform.tfvars` file by copying the `terraform.tfvars.example` file.

    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```

    Edit `terraform.tfvars` and provide the required values:
    *   `project_id`: Your GCP Project ID.
    *   `allowed_psc_projects`: A list of project IDs that can connect to the Cloud SQL instance. **You must include your own project ID here.**
    *   `psc_subnet_cidr_range`: A unique `/29` CIDR block that does not overlap with any other subnets in your VPC (e.g., `"10.10.0.0/29"`).

3.  **Initialize Terraform**:
    Run the following command to download the necessary provider plugins.
    ```bash
    terraform init
    ```

4.  **Review and Apply**:
    Review the execution plan and then apply the configuration.
    ```bash
    terraform plan
    terraform apply
    ```
    When prompted, type `yes` to confirm the deployment.

## Post-Deployment: Granting User Permissions

For security, you must manually grant the necessary permissions to the `datastream` user after the instance is created.

1.  Connect to the database using the Cloud Shell or a bastion host.
2.  Execute the following SQL query:
    ```sql
    GRANT REPLICATION SLAVE, SELECT, EXECUTE ON *.* TO 'datastream'@'%';
    FLUSH PRIVILEGES;
    ```

## Terraform Resources

This project creates the following main resources:

*   `google_sql_database_instance.mysql_instance`
*   `google_sql_user.datastream_user`
*   `google_compute_subnetwork.datastream_psc_subnet`
*   `google_compute_network_attachment.ds_to_sql_attachment`
*   `google_compute_firewall.allow_datastream_psc_to_sql`
*   `google_datastream_private_connection.default`
*   `google_datastream_connection_profile.mysql_source_profile`

## Clean Up

To delete all the resources created by this project, run:
```bash
terraform destroy
```

## Troubleshooting

### Error: "Cannot modify allocated ranges in CreateConnection"

If you encounter the following error during `terraform apply`, it means that a Service Networking Connection for your VPC already exists and was not created by Terraform.

```
Error: Error waiting for Create Service Networking Connection: Error code 9, message: Cannot modify allocated ranges in CreateConnection. Please use UpdateConnection.
```

This happens because Terraform's state is not synchronized with the actual resources in your GCP project. To resolve this, you must import the existing connection into the Terraform state.

**Solution Steps:**

1.  **Add Existing IP Ranges to your `.tfvars` file**:
    First, identify the existing IP ranges from the error message and add them to a new variable in your `terraform.tfvars` file.

    ```hcl
    # terraform/terraform.tfvars

    existing_peering_ranges = ["default-ip-range"] 
    # Add any other ranges listed in the error, e.g., "mysql-instance-for-datastream-private-ip"
    ```
    *Note: You will also need to add the `existing_peering_ranges` variable definition to `variables.tf`.*

2.  **Import the Existing Connection**:
    Run the `terraform import` command to bring the existing resource under Terraform's management. The correct ID format is `{network_name}:{service_name}`.

    ```bash
    terraform import 'google_service_networking_connection.private_vpc_connection' 'default:servicenetworking.googleapis.com'
    ```

3.  **Verify and Apply**:
    Run `terraform plan` to confirm that Terraform now intends to *change* the existing resource instead of creating a new one. If the plan is correct, run `terraform apply` to finalize the changes.
