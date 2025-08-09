# GEMINI.md

This guide helps AI-based development tools like Gemini understand and interact with this project effectively.

## Project Overview

This project uses Terraform to manage and provision a GCP Datastream pipeline that captures changes from a Cloud SQL for MySQL database and replicates them to BigQuery. The infrastructure is deployed in **two distinct stages**:

1.  **`terraform/01-network`**: Provisions the core network infrastructure (VPC, subnets, firewall, NAT, Service Networking).
2.  **`terraform/02-app-infra`**: Provisions the application-specific resources (Cloud SQL, BigQuery, Datastream) that depend on the network.

This two-stage approach separates the network lifecycle from the application lifecycle, which is a security and operational best practice.

## Development Workflow

Deployment and management must be performed in order for each stage.

### Stage 1: Network (`01-network`)

1.  **Navigate to the directory:**
    ```bash
    cd terraform/01-network
    ```
2.  **Initialize Terraform:**
    This downloads the necessary providers.
    ```bash
    terraform init
    ```
3.  **Plan and Apply:**
    Review and deploy the network resources.
    ```bash
    terraform plan
    terraform apply
    ```

### Stage 2: Application Infrastructure (`02-app-infra`)

This stage depends on the successful completion of Stage 1. It reads the network configuration from the state file of the first stage.

1.  **Navigate to the directory:**
    ```bash
    cd terraform/02-app-infra
    ```
2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
3.  **Plan and Apply:**
    Review and deploy the application resources.
    ```bash
    terraform plan
    terraform apply
    ```

## Core Terraform Commands

The following commands are essential for managing the infrastructure and should be run from within the respective stage directory (`01-network` or `02-app-infra`).

*   **`terraform fmt -recursive`**: Format all Terraform files.
*   **`terraform validate`**: Validate the syntax of the configuration.
*   **`terraform plan`**: Create an execution plan.
*   **`terraform apply`**: Apply the changes to the infrastructure.
*   **`terraform destroy`**: Destroy the resources managed by the configuration.

## Key Files and Directories

*   **`terraform/01-network/`**: Contains all configuration for the network infrastructure.
    *   `vpc.tf`: Defines the VPC, subnets, NAT, router, and firewall rules.
    *   `outputs.tf`: Defines the outputs (e.g., VPC ID) that are consumed by Stage 2.
*   **`terraform/02-app-infra/`**: Contains all configuration for the application stack.
    *   `main.tf`: Defines the provider and the `terraform_remote_state` data source to read from Stage 1.
    *   `cloudsql_mysql.tf`: Defines the Cloud SQL instance and users.
    *   `bigquery.tf`: Defines the BigQuery destination dataset.
    *   `datastream.tf`: Defines all Datastream-related resources.
*   **`FAQ.md`**: Contains a detailed FAQ about the project's architecture and common issues.