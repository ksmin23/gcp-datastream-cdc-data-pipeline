# FAQ

---

## Setup & Operations

### Q: Which GCP APIs need to be enabled before running `terraform apply`?

**A:**

Yes, certainly. Here is a step-by-step list of the APIs that need to be enabled in your GCP project before you run `terraform apply`.

For both stages to execute successfully, the APIs below must be **enabled in advance**.

#### Complete List of Required APIs

The following is a comprehensive list of all APIs required to create the resources in this project.

1.  **Compute Engine API**: `compute.googleapis.com`
    *   **Purpose**: Creates and manages all networking resources, including VPCs, subnets, firewall rules, Cloud Routers, Cloud NAT, and Network Attachments.
    *   **Required in Stage**: `01-network`, `02-app-infra`

2.  **Service Networking API**: `servicenetworking.googleapis.com`
    *   **Purpose**: Sets up VPC Peering to allow the Cloud SQL instance to communicate privately with your VPC.
    *   **Required in Stage**: `01-network`

3.  **Cloud SQL Admin API**: `sqladmin.googleapis.com`
    *   **Purpose**: Creates and manages the Cloud SQL for MySQL instance and users.
    *   **Required in Stage**: `02-app-infra`

4.  **Datastream API**: `datastream.googleapis.com`
    *   **Purpose**: Creates and manages Datastream private connections, connection profiles, and stream resources.
    *   **Required in Stage**: `02-app-infra`

5.  **BigQuery API**: `bigquery.googleapis.com`
    *   **Purpose**: Creates and manages the BigQuery dataset and connection profiles that will serve as the destination for Datastream.
    *   **Required in Stage**: `02-app-infra`

6.  **Cloud Resource Manager API**: `cloudresourcemanager.googleapis.com`
    *   **Purpose**: Required for Terraform to query and manage resources in the project. It is often enabled by default.

#### `gcloud` Command for API Activation

The most convenient method is to run the following command in Cloud Shell or a local environment with the `gcloud` CLI installed to enable all required APIs at once.

```bash
# Run the command below to enable all necessary APIs.
# Replace your-gcp-project-id with your actual project ID.

gcloud services enable \
    compute.googleapis.com \
    servicenetworking.googleapis.com \
    sqladmin.googleapis.com \
    datastream.googleapis.com \
    bigquery.googleapis.com \
    cloudresourcemanager.googleapis.com \
    --project=your-gcp-project-id
```

Running this command first will ensure a smooth resource creation process without API-related errors during `terraform apply`.

---

### Q: What is the `gcloud` command to start a Datastream Stream created by `terraform apply`?

**A:**

The `gcloud` command to start a Datastream Stream that was created in a `NOT_STARTED` state by `terraform apply` is as follows.

#### Basic Command

```bash
gcloud datastream streams update [STREAM_NAME] \
    --location=[REGION] \
    --state=RUNNING
```

*   **`[STREAM_NAME]`**: The name of the Datastream Stream you want to start. (Terraform variable: `var.stream_name`)
*   **`[REGION]`**: The GCP region where the Stream was created. (Terraform variable: `var.region`)
*   **`--state=RUNNING`**: The key part that sets the target state of the Stream to 'running'.

#### Example

If your Stream is named `mysql-to-bigquery-stream` and is in the `us-central1` region, you would run:

```bash
gcloud datastream streams update mysql-to-bigquery-stream \
    --location=us-central1 \
    --state=RUNNING
```

#### Additional Option: `--force`

If you want to forcibly start the stream even if there are validation warnings, you can add the `--force` flag. However, you should only use this if you fully understand the content of the warnings.

---

## Terraform & Resource Management

### Q: When configuring Datastream and Cloud SQL replication, which resources should be created only once per project and shared?

**A:**

Yes, based on the provided Terraform code, here is a summary of the resources that should be **created only once per GCP project and then shared**.

These resources typically act as a "connection" or "configuration" between specific networks or services, and multiple data pipelines or instances will use this shared infrastructure.

#### List and Description of Shared Resources

##### 1. `google_service_networking_connection`

*   **Resource Name**: `private_vpc_connection`
*   **Role**: Creates a **VPC Network Peering** that connects your VPC with the VPC of Google-managed services (like Cloud SQL).
*   **Reason for Sharing**: This connection can **only exist once per VPC network**. Once created, all resources within that VPC use this single connection to privately access services like Cloud SQL. Even if you create multiple Cloud SQL instances, this one connection is used.
*   **Analogy**: It's like a **single, dedicated private bridge** connecting 'your city (your VPC)' to the 'Google services city'.

##### 2. `google_compute_global_address`

*   **Resource Name**: `private_ip_address`
*   **Role**: **Reserves a private IP address range** that will be allocated to Cloud SQL instances through the 'Service Networking connection' described above.
*   **Reason for Sharing**: Since the `google_service_networking_connection` exists only once per VPC, the task of reserving an IP range for this connection must also be managed centrally. If multiple pipelines tried to add different IP ranges to this connection, conflicts could arise. Therefore, this resource is typically **created once for a single `google_service_networking_connection`**, and if multiple Cloud SQL instances are needed, they are configured to receive IPs from within this reserved range.
    *   *(Advanced: While you can have multiple reserved ranges, for management purposes, it's best to manage them with a single, central Terraform configuration.)*

##### 3. `google_compute_network_attachment`

*   **Resource Name**: `ds_to_sql_attachment`
*   **Role**: Creates a **'network connection point'** via PSC (Private Service Connect) to allow external services like Datastream to enter your VPC.
*   **Reason for Sharing**: This resource is sufficient to have **once per combination of VPC network and region**. Once created, all PSC-based services (like Datastream, Vertex AI, etc.) entering that VPC and region will share this single connection point.
*   **Analogy**: It's like a **'dedicated entrance for Google services'** built into 'your company building (your VPC)'.

##### 4. `google_compute_subnetwork` (for PSC)

*   **Resource Name**: `datastream_psc_subnet`
*   **Role**: Creates a **dedicated subnet** for the `google_compute_network_attachment` to use.
*   **Reason for Sharing**: Since the Network Attachment is a shared resource, the subnet it uses is also shared. This subnet serves as a dedicated space for PSC connections and isolates them from other VMs or services.

#### Summary Table

| Resource Type | Terraform Resource Name | Scope | Why It Should Be Shared |
| :--- | :--- | :--- | :--- |
| `google_service_networking_connection` | `private_vpc_connection` | VPC Network | Can only be created once per VPC. A single gateway for all private service access. |
| `google_compute_global_address` | `private_ip_address` | Service Networking Connection | IP reservations for the above connection must be managed centrally to avoid conflicts. |
| `google_compute_network_attachment` | `ds_to_sql_attachment` | VPC Network + Region | A single entry point shared by all PSC services entering the VPC/region. |
| `google_compute_subnetwork` | `datastream_psc_subnet` | Network Attachment | As the dedicated subnet for the Network Attachment, it is shared along with it. |

---

### Q: If I have already created a `google_service_networking_connection` for another Cloud SQL instance (A), can I not create it again for a new instance (B)?

**A:**

That's correct. **You cannot create it again, and you don't need to.**

The `google_service_networking_connection` is like a "dedicated bridge" that **exists only once per VPC**. Once this bridge is built, all services belonging to that VPC share it.

#### Key Concept: One Bridge, Multiple Plots of Land

*   **`google_service_networking_connection` (The Dedicated Bridge)**: This resource is a single connection between one VPC and Google's services. If you've already created it for instance A, all Google services will continue to use that bridge.
*   **`google_compute_global_address` (IP Address Range, i.e., The Plot of Land)**: When you create a new Cloud SQL instance B, you reuse the existing "bridge" and simply **reserve a new "plot of land" (private IP address range)** on the other side.

#### Conclusion

In a single VPC, you create the `google_service_networking_connection` resource only once. When adding new Cloud SQL instances later, you only need to add a new `reserved_peering_ranges` to that existing connection. Therefore, it is correct that you "cannot create it again," and if it already exists, you must reuse it.

---

### Q: When connecting Datastream and Cloud SQL via PSC, should a Network Attachment be created for each Cloud SQL instance, or just once?

**A:**

The short answer is: **you only need to create the Network Attachment once.**

It is not necessary to create one for each Cloud SQL instance you want to connect to.

#### Why Only Once? (An Analogy)

You can think of the Network Attachment's role as a **'dedicated entrance for Google services'**.

*   **Your VPC Network**: This is your 'company building', isolated from the outside.
*   **Network Attachment**: This is the **'dedicated entrance for Google services'** built into your 'company building'. This entrance is the official pathway for all Google services that support PSC, like Datastream and Vertex AI, to enter your building.
*   **Cloud SQL Instances (A, B, C...)**: These are the 'partner offices' outside your building that need to collaborate with you.

Just as you wouldn't build a new entrance to your company building every time a new partner company comes along, the same principle applies here.

#### Technical Explanation

*   **Scope of a Network Attachment**: The `google_compute_network_attachment` resource is not tied to a specific Cloud SQL instance but to a **VPC network** and a **region**.
*   **Connection Flow**: A service like Datastream enters the consumer's VPC through this Network Attachment and is then routed through the PSC infrastructure to the specific target Cloud SQL instance.

#### Conclusion

For a **single VPC network** and **single region** combination, **one Network Attachment** is sufficient. If you want to connect to multiple Cloud SQL instances within that VPC/region, all connections will share the one Network Attachment you have already created.

---

### Q: What problems can occur if I create multiple Network Attachments?

**A:**

While it might technically work, creating multiple Network Attachments can lead to several management, cost, and potential performance issues.

1.  **Unnecessary Costs**: A Network Attachment is a resource that is billed hourly. If you create multiple, you will be paying for unused Attachments.

2.  **Increased Management Complexity (The Biggest Problem)**:
    *   **Confusing Architecture**: It creates confusion like, "Which service is using which Attachment?", making it difficult to diagnose issues during an outage.
    *   **Terraform Code Duplication**: Having multiple, nearly identical resource blocks clutters the code, harms readability, and makes maintenance difficult.
    *   **Complex Firewall Rules**: You would need to manage separate subnets and firewall rules for each Attachment, complicating security policies and increasing the chance of mistakes.

3.  **Resource Quota Issues**: All GCP resources are subject to quotas. Creating unnecessary Attachments might prevent you from creating one when you actually need it later.

4.  **Potential Performance and Routing Issues**: An unnecessarily complex network configuration can create inefficient traffic paths, potentially leading to minor increases in latency. It also makes debugging much more complicated when problems arise.

#### Conclusion

Creating multiple Network Attachments is like **unnecessarily building multiple front doors in a single building that all lead to the same place**. Adhering to the **"1 VPC, 1 Region, 1 Network Attachment"** principle is the most efficient and correct architectural design in terms of cost, management, and performance.

---

## Networking

### Q: What GCP resource does the `google_service_networking_connection` Terraform resource block create?

**A:**

The `google_service_networking_connection` resource is responsible for creating a **private communication channel** between **your VPC network** and the **VPC network of Google-managed services** (e.g., Cloud SQL).

Technically, this channel is called **VPC Network Peering**.

#### Simple Analogy: A Private Bridge

To understand this concept easily, let's use an analogy.

*   **Your VPC Network**: This is 'your city' that you own. Your virtual machines (VMs) and other services live here.
*   **Google's Service VPC Network**: This is the 'Google services city' owned and managed by Google. Google's managed services like Cloud SQL and Memorystore live here.
*   **`google_service_networking_connection`**: This is a **private, dedicated bridge** connecting 'your city' and the 'Google services city'.

Without this bridge, services in 'your city' would have to use the public internet to access Cloud SQL in the 'Google services city'. But by building this dedicated bridge, they can communicate directly, securely, and quickly without going out into the public.

#### Mapping Code to Actual Resources

Let's look at how the code block in `main.tf` creates this 'dedicated bridge'.

```terraform
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.main_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [...] 
}
```

*   `network`: Specifies the starting point of the 'dedicated bridge', which is **your VPC network**.
*   `service`: Specifies the destination of the 'dedicated bridge', connecting to the **city where Google's managed services are located**.
*   `reserved_peering_ranges`: This is the most crucial part. It **reserves a private IP address range** in the 'Google services city' for your Cloud SQL instance to use. It's like telling them, "Once the bridge is connected, please build a house (IP address) for my Cloud SQL within this range."

#### Core Purposes

1.  **Private IP Communication**: Allows resources in your VPC to communicate with the Cloud SQL instance using its private IP, not a public one.
2.  **Enhanced Security**: Greatly improves security by eliminating the need to expose your database to the public internet.
3.  **Simplified Networking**: Allows you to use Google-managed services as if they were inside your own VPC, without complex firewall or VPN configurations.

In conclusion, this resource is an essential "network bridge" for integrating your infrastructure with Google's managed services securely and efficiently.

---

### Q: Where can I verify the VPC Peering for a private Cloud SQL connection?

**A:**

That's an excellent question. The VPC Peering used for Cloud SQL's private IP connection is managed slightly differently from standard VPC Peering, and the location to verify it is specific.

The short answer is that you check it on the **standard VPC Network Peering page**, but you need to look for a **special, Google-managed peering connection**.

#### How Cloud SQL Private Connections Work (Private Services Access)

First, understanding the principle makes it easier.

*   When a user creates a Cloud SQL instance with a 'private IP', Google internally provisions that SQL instance in a **Google-owned VPC network**.
*   Then, it automatically sets up **VPC Network Peering** between the user's VPC and the Google-owned VPC.
*   This mechanism is called **'Private Services Access'**.

Therefore, what we need to find is the peering connection between our project's VPC and Google's service VPC.

#### How to Verify

##### 1. Verify in the Google Cloud Console (Web UI)

1.  Log in to the Google Cloud Console.
2.  Navigate to **Navigation menu (☰)** > **VPC network** > **VPC network peering**.
3.  In the table, look for a peering connection with the following characteristics:

    *   **Name**: `servicenetworking-googleapis-com`
    *   **Peer project ID**: `servicenetworking` or another Google-owned project ID.
    *   **State**: Must be `ACTIVE`.

    *   The connection named **`servicenetworking-googleapis-com`** is the VPC Peering for private connections to Google-managed services like Cloud SQL and Memorystore.
    *   If the **state is `ACTIVE`**, it means the network path between your VPC and the Google service VPC (where Cloud SQL resides) has been successfully established.

##### 2. Verify with the `gcloud` CLI (Command-Line Tool)

You can also verify this by running the following command in your terminal:

```bash
gcloud compute networks peerings list --network=[YOUR_VPC_NAME]
```

*   Replace `[YOUR_VPC_NAME]` with the name of your actual VPC network.

**Example Output:**

```
NAME: servicenetworking-googleapis-com
NETWORK: default
PEER_PROJECT: servicenetworking
STATE: ACTIVE
STATE_DETAILS: [OK]
```

If the `servicenetworking-googleapis-com` peering appears with an `ACTIVE` state like this, it is connected correctly.

#### Summary

| Item | Details |
| :--- | :--- |
| **Verification Location** | **VPC network > VPC network peering** page |
| **Name to Look For** | `servicenetworking-googleapis-com` |
| **Core Concept** | Private Services Access |
| **Normal State** | `ACTIVE` |

---

## Datastream

### Q: What is the default value for `desired_state` in the `google_datastream_stream` resource?

**A:**

According to the official Terraform documentation, the `desired_state` argument has **no explicit default value**.

However, if you **omit** this argument from your code, Terraform will not pass a `desired_state` value to the GCP API. In this case, following the default behavior of the GCP Datastream API, the Stream will be created in the **`NOT_STARTED`** state.

#### Behavior Summary by Scenario

| `desired_state` Setting | Terraform Action | Final Stream State | Description |
| :--- | :--- | :--- | :--- |
| **Argument Omitted** | Does not include the `desired_state` field in the API call | **`NOT_STARTED`** | **(GCP API Default Behavior)** The resource is created, but data replication has not begun. |
| `desired_state = "RUNNING"` | Sets `desired_state` to "RUNNING" in the API call | `RUNNING` | Immediately starts the stream to begin data replication after resource creation. |
| `desired_state = "PAUSED"` | Sets `desired_state` to "PAUSED" in the API call | `PAUSED` | Immediately places the stream in a paused state after resource creation. |

Therefore, if you omit the `desired_state` line from your code, the Stream will be safely created in a `NOT_STARTED` state, allowing you to start it manually later.

---

### Q: Considering Datastream's configuration, how are multiple databases and tables stored in BigQuery?

**A:**

Datastream preserves the **hierarchy** of the source (MySQL) in the destination (BigQuery).

*   **MySQL Hierarchy**: `Database (Schema) → Table`
*   **BigQuery Hierarchy**: `Project → Dataset → Table`

Datastream maps a MySQL `database` to a BigQuery `dataset` and a MySQL `table` to a BigQuery `table`, thus preserving this structure.

#### Storage Method: The `source_hierarchy_datasets` Setting

This behavior is controlled by the **`source_hierarchy_datasets`** setting within the `bigquery_destination_config` block of the `google_datastream_stream` resource.

```terraform

destination_config {
  bigquery_destination_config {
    source_hierarchy_datasets {
      dataset_template {
        location = var.bigquery_dataset_location
        dataset_id_prefix = "my_cdc_data" // Example prefix
      }
    }
  }
}
```

#### Specific Storage Example

If your source MySQL has `sales_db` and `inventory_db` databases, the following datasets and tables will be created in BigQuery:

*   **`my_cdc_data_sales_db`** (Dataset)
    *   `customers` (Table)
    *   `orders` (Table)
*   **`my_cdc_data_inventory_db`** (Dataset)
    *   `products` (Table)

**Summary Rule:**
> BigQuery Dataset Name = **`[dataset_id_prefix]_[source_database_name]`**

This method ensures that the logical separation of the source is maintained in BigQuery, making it very easy to identify and manage the data.

#### Additional Metadata in BigQuery Tables

Each table created in BigQuery includes all the columns from the source table, plus useful **metadata columns** added by Datastream.

| Metadata Column | Description |
| :--- | :--- |
| `datastream_metadata.uuid` | A unique identifier for each row. |
| `datastream_metadata.source_timestamp` | The actual time the change occurred at the source. |
| `datastream_metadata.is_deleted` | A `BOOLEAN` value indicating whether the row was `DELETE`d at the source (Soft-delete). |

This metadata enables sophisticated, time-based data analysis.