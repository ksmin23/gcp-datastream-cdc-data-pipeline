# GEMINI.md

This guide helps AI-based development tools like Gemini understand and interact with this project effectively.

## Project Overview

This project uses Terraform to manage and provision Google Cloud Platform (GCP) infrastructure. It defines the desired state of the infrastructure in `.tf` files, which Terraform then uses to create, update, and delete resources.

## Development Environment Setup

To work with this project, you need to have Terraform installed on your system.

**Installing Terraform:**

1.  **Download Terraform:** Visit the official Terraform website to download the appropriate package for your operating system: [https://www.terraform.io/downloads.html](https://www.terraform.io/downloads.html)
2.  **Installation:** Follow the installation instructions provided for your OS. Typically, this involves unzipping the package and adding the Terraform binary to your system's PATH.

**Setup Steps:**

1.  **Navigate to the Terraform directory:**
    Open your terminal and change to the `terraform` directory, which contains all the Terraform configuration files.
    ```bash
    cd terraform
    ```

2.  **Initialize Terraform:**
    Run `terraform init` from within the `terraform` directory. This command downloads the necessary provider plugins (in this case, for Google Cloud) and sets up the backend for storing state.
    ```bash
    terraform init
    ```

## Core Terraform Commands

The following commands are essential for managing the infrastructure defined in this project and should be run from within the `terraform` directory.

1.  **Formatting:**
    Ensure your code is correctly formatted before proceeding.
    ```bash
    terraform fmt
    ```

2.  **Validation:**
    Validate the syntax of the Terraform files.
    ```bash
    terraform validate
    ```

3.  **Plan:**
    Create an execution plan. This command shows you what actions Terraform will take to achieve the desired state defined in your configuration files. It's a dry run and is safe to use at any time.
    ```bash
    terraform plan
    ```

4.  **Apply:**
    Apply the changes required to reach the desired state. Terraform will show you the plan again and ask for confirmation before making any changes to your infrastructure.
    ```bash
    terraform apply
    ```

5.  **Destroy:**
    Destroy all the resources managed by this Terraform configuration. This is irreversible.
    ```bash
    terraform destroy
    ```

## Debugging

When you encounter errors while running Terraform commands, it is crucial to refer to the official Terraform documentation for debugging and resolution. The documentation provides detailed explanations of errors and step-by-step guides to fix them.

- [Terraform Documentation](https://www.terraform.io/docs)

## Code Style and Linting

This project follows the standard Terraform conventions. All commands should be run from the `terraform` directory.

-   **Formatting:** Use `terraform fmt` to automatically format all `.tf` files in the current directory and its subdirectories.
    ```bash
    terraform fmt
    ```
-   **Linting/Validation:** Use `terraform validate` to check for syntax errors and inconsistencies in your configuration.
    ```bash
    terraform validate
    ```

## Key Files and Directories

All Terraform files (`.tf`, `.tfvars`) are located within the `terraform/` directory.

-   `terraform/main.tf`: The main configuration file, where resources are defined.
-   `terraform/variables.tf`: Contains declarations for input variables used in the configuration.
-   `terraform/outputs.tf`: Defines output values from your Terraform configuration (e.g., IP addresses, instance IDs).
-   `terraform/terraform.tfvars`: A file to provide values for the declared variables. This file is often excluded from version control to avoid committing sensitive information.
-   `terraform/.terraform/`: A local directory where Terraform keeps track of plugins and modules. It's created automatically by `terraform init`.
-   `terraform/.terraform.lock.hcl`: A dependency lock file that records the provider versions used for the configuration.

## Coding Conventions

-   **Naming:** Use `snake_case` for all resource names, data source names, and variables.
-   **Resources:** Define resources in a logical and organized manner within `main.tf` or other `.tf` files.
-   **Variables:** Declare all variables in `variables.tf` with clear descriptions. Provide default values where appropriate.
-   **Outputs:** Define meaningful outputs in `outputs.tf` to expose important information about the created infrastructure.
