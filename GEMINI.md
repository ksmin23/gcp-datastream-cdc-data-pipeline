# GEMINI.md

This guide helps AI-based development tools like Gemini understand and interact with this project effectively. Its primary purpose is to ensure that any modifications maintain the established architectural principles and coding conventions.

## 1. Core Project Philosophy

The most important principle of this project is the **strict separation of concerns** between network infrastructure and application infrastructure.

-   **`terraform/01-network`**: Manages foundational, slowly-changing network resources. This is the base layer.
-   **`terraform/02-app-infra`**: Manages application-specific resources that depend on the network. This layer is built upon the base.

**Golden Rule**: Any change must respect this two-stage separation. Never add application resources to the `01-network` stage, and never add foundational network resources to the `02-app-infra` stage. The link between them is the `terraform_remote_state` data source in `02-app-infra`, which reads outputs from `01-network`.

## 2. Development Workflow

Always follow the two-stage workflow. Changes must be planned and applied to each stage in order, starting with the network.

1.  Navigate to the correct stage directory (`01-network` or `02-app-infra`).
2.  Initialize with `terraform init`.
3.  Always preview changes with `terraform plan` before applying.
4.  Apply changes with `terraform apply`.

## 3. Coding and Style Conventions

Adherence to these conventions is critical for maintaining project consistency.

### 3.1. Terraform Conventions

-   **Formatting**: All Terraform files (`.tf`) **must** be formatted using `terraform fmt -recursive`. Before committing any change, run this command from the root of the repository.
-   **Naming Conventions**:
    -   **Resources**: Use a consistent `google_resource_type.descriptive_name` format. The name should clearly indicate the resource's purpose. For example: `google_datastream_stream.mysql_to_bigquery_stream`.
    -   **Variables**: Use `snake_case`. Define all variables in `variables.tf` with a clear `description` and a `type`. Provide sensible defaults where applicable.
    -   **Outputs**: Use `snake_case`. Define all outputs in `outputs.tf` with a `description`.
-   **File Organization**:
    -   Keep related resources within the same file. For example, all VPC-related resources (VPC, subnets, firewall rules) are in `vpc.tf`. All Datastream resources are in `datastream.tf`.
    -   Do not create deeply nested modules. This project prefers a flat file structure within each stage for clarity.
-   **Comments**: Use comments (`#`) sparingly. Focus on explaining the *why* behind a complex configuration, not the *what*.

### 3.2. Documentation Conventions (`README.md`, `FAQ.md`)

-   **`README.md`**: This file should contain a high-level overview, the architecture diagram, and setup/usage instructions. It's the entry point for a human user.
-   **`FAQ.md`**: This file is for detailed, deep-dive questions and answers about specific architectural decisions, common problems, or technical concepts.
-   **Diagrams**: Use `mermaid` syntax for all diagrams to ensure they can be rendered directly in Markdown.
-   **Tone**: Maintain a clear, professional, and helpful tone.

## 4. Guide for Making Changes (for AI Assistants)

When asked to modify the project, follow these steps:

1.  **Identify the Correct Stage**: First, determine if the requested change belongs to `01-network` or `02-app-infra`.
    -   *Is it a core network component like a VPC, subnet, or firewall rule?* → `01-network`.
    -   *Is it an application service like Cloud SQL, BigQuery, or Datastream?* → `02-app-infra`.
2.  **Follow Conventions**:
    -   Adhere strictly to the naming and formatting conventions outlined in Section 3.
    -   Place the new resource definition in the appropriate `.tf` file alongside related resources.
3.  **Validate Your Changes**: Before finalizing, always run `terraform fmt -recursive` and `terraform validate` from the relevant stage directory to ensure correctness and style compliance.
4.  **Update Documentation**: If the change introduces a new feature, alters the architecture, or might raise new questions, update `README.md` or add a new entry to `FAQ.md`.
5.  **Commit Message**: Write a clear and concise commit message that explains the change. Use conventional commit prefixes if applicable (e.g., `feat:`, `fix:`, `docs:`).