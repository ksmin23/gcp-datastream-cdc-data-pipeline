# GEMINI.md

This guide helps AI-based development tools like Gemini understand and interact with this project effectively. Its primary purpose is to ensure that any modifications maintain the established architectural principles and coding conventions for **both Terraform and Python code**.

## 1. Core Project Philosophy

The project is divided into two main parts with distinct purposes:

-   **`terraform/`**: Contains the core Infrastructure as Code (IaC) to provision the GCP data pipeline. This is the primary infrastructure definition.
-   **`scripts/`**: Contains supplementary Python scripts for tasks like generating test data, automation, or validation. This is for operational support, not infrastructure.

**Golden Rule**: Maintain the strict separation between these two directories. Terraform code belongs exclusively in `terraform/`, and Python utility scripts belong in `scripts/`.

## 2. Coding and Style Conventions

Adherence to language-specific conventions is critical for maintaining project consistency.

### 2.1. For Terraform Code (`terraform/` directory)

-   **Workflow**: All `terraform` commands (`init`, `plan`, `apply`) must be run from within the appropriate stage directory (`01-network` or `02-app-infra`).
-   **Formatting**: All `.tf` files **must** be formatted using `terraform fmt -recursive`.
-   **Naming Conventions**:
    -   **Resources**: `google_resource_type.descriptive_name` (e.g., `google_datastream_stream.mysql_to_bigquery_stream`).
    -   **Variables & Outputs**: `snake_case`.
-   **File Organization**: Keep related resources within the same file (e.g., all Datastream resources in `datastream.tf`).

### 2.2. For Python Code (`scripts/` directory)

This project uses `uv` for fast Python environment and package management.

-   **Environment Setup**:
    1.  Create the virtual environment: `uv venv` (run inside `scripts/`)
    2.  Activate it: `source .venv/bin/activate`
    3.  Install dependencies: `uv pip install -r requirements.txt`
-   **Running Scripts**: Always run scripts through `uv` to ensure the correct environment is used.
    ```bash
    # Example from the root directory
    cd scripts
    uv run python generate_fake_sql.py --help
    ```
-   **Style and Linting**:
    -   **Formatting**: All Python code must be formatted with **Black**.
        ```bash
        uv run black .
        ```
    -   **Linting**: Code should be checked with **Ruff**.
        ```bash
        uv run ruff check .
        ```
-   **Dependency Management**:
    -   To add a new dependency, add the package name to `scripts/requirements.txt`.
    -   Then, run `uv pip install -r scripts/requirements.txt` to install it into the virtual environment.

## 3. Guide for Making Changes (for AI Assistants)

When asked to modify the project, follow these steps:

1.  **Identify the Context (Terraform or Python)**: First, determine which part of the project the request applies to.
    -   *Is it about provisioning infrastructure (e.g., "add a new firewall rule")?* → **Terraform context**.
    -   *Is it about a utility script (e.g., "add a new field to the fake data")?* → **Python context**.
2.  **Navigate to the Correct Directory**: Before taking any action, change to the relevant directory (`terraform/01-network`, `terraform/02-app-infra`, or `scripts/`).
3.  **Follow Language-Specific Conventions**:
    -   For **Terraform**, adhere to the conventions in section 2.1.
    -   For **Python**, adhere to the conventions in section 2.2. This includes setting up the `uv` environment if it doesn't exist.
4.  **Validate Your Changes**:
    -   **Terraform**: Run `terraform fmt` and `terraform validate`.
    -   **Python**: Run `uv run black .` and `uv run ruff check .`.
5.  **Update Documentation**: If the change impacts how a user runs the project, update `README.md` or `FAQ.md`.
6.  **Commit Message**: Write a clear commit message, specifying the context, e.g., `feat(terraform): ...` or `fix(scripts): ...`.

## 4. AI Assistant Guide: How to Use Library Documentation

When you need to consult official library documentation to fix a bug or write code, you must follow this workflow. This provides more accurate and structured information than a general web search.

**Priority Workflow:**

1.  **Resolve Library ID (`resolve-library-id`):**
    To find the precise Context7-compatible ID for a requested library (e.g., `requests`, `Next.js`), **first** use the `resolve-library-id` tool.

2.  **Get Documentation (`get-library-docs`):**
    Use the ID obtained in the previous step to call the `get-library-docs` tool. If necessary, specify the `topic` parameter to retrieve documentation on a specific subject.

3.  **Modify or Write Code:**
    Based on the official documentation retrieved, modify or write the code as requested by the user.

**Actions to Avoid:**

*   Do not use the `google_web_search` tool for the purpose of finding library documentation.
*   Only use `google_web_search` as an alternative in exceptional cases where the `resolve-library-id` or `get-library-docs` tools fail or cannot find the relevant library.