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

### Q: Is it necessary to enable Private Service Access (PSA) for Cloud SQL when connecting from Datastream using Private Service Connect (PSC)?

**A:**

No, it is **not necessary to enable Private Service Access (PSA)**.

The short answer is that PSC and PSA are **two different methods for private connectivity**. Datastream is designed to use PSC, which functions independently of PSA.

#### Detailed Explanation: Private Service Connect (PSC) vs. Private Service Access (PSA)

Understanding the difference between these two technologies is key. Both provide private connectivity, but they operate differently and have distinct use cases.

| Feature | **Private Service Access (PSA)** | **Private Service Connect (PSC)** |
| :--- | :--- | :--- |
| **Core Concept** | **VPC Peering** | **Service Endpoint** |
| **Connection Model** | **VPC-to-VPC Connection**<br>Connects your entire VPC to a Google services VPC. | **Service-to-VPC Connection**<br>Exposes a specific service (like a Cloud SQL instance) as an internal IP address inside your VPC. |
| **IP Management** | Requires you to **reserve** an IP range in your VPC. | Does not require a reserved IP range.<br>It consumes a single internal IP address from your VPC's subnet. |
| **Analogy** | **A Private Bridge**<br>Builds a bridge connecting your city to the Google services city. | **A Private Entrance**<br>Creates a dedicated entrance for a specific partner (Cloud SQL) inside your own building. |
| **Key Resource** | `google_service_networking_connection` | `google_compute_network_attachment`<br>(Used by the service producer, consumed by a forwarding rule) |

#### Why Datastream Doesn't Need PSA

1.  **Datastream is a Service Consumer:** Datastream needs to connect to a specific published service (Cloud SQL). PSC is designed precisely for this service-centric connection model.

2.  **PSC's Connection Method:**
    *   The Cloud SQL instance acts as a "published service."
    *   Datastream accesses this published service through a **Network Attachment** created in your VPC.
    *   This process establishes a private path to the service itself, independent of the VPC-wide peering created by PSA. Therefore, building the PSA "bridge" is not required for this scenario.

#### Summary

*   **Private Service Access (PSA)** uses **VPC Peering** to connect your VPC to a Google services VPC.
*   **Private Service Connect (PSC)** exposes a specific service as a **private endpoint** inside your VPC.
*   Datastream uses **PSC** to connect to Cloud SQL.
*   Therefore, in a scenario where you are connecting Datastream to Cloud SQL via PSC, **you do not need to enable PSA.**

---

### Q: If Private Service Access (PSA) isn't needed for Datastream with PSC, can a user in the VPC also connect to Cloud SQL securely using only PSC, without PSA?

**A:**

Yes, absolutely. When you need to securely access Cloud SQL for MySQL from within your VPC (e.g., from a GCE VM), you can **connect using only Private Service Connect (PSC) without needing Private Service Access (PSA)**. In fact, for modern architectures, this is often the recommended approach.

#### How is it possible to connect from the VPC using only PSC?

This is possible because PSC makes the Cloud SQL instance appear **as if it were a native resource within your own VPC**.

##### How PSC Works for In-VPC Access

1.  **Service Publishing**: The Cloud SQL instance makes itself available as a "published service" via PSC, ready for authorized consumers to connect.
2.  **Endpoint Creation**: You create a PSC **endpoint** within your own VPC that points to this published Cloud SQL service.
    *   In GCP, the actual resource for this endpoint is a **Forwarding Rule**.
    *   This forwarding rule is assigned an **internal IP address from your VPC's own subnet**.
3.  **Connection**: Now, VMs or other resources inside your VPC connect to Cloud SQL using this new internal IP address, not the original Cloud SQL IP.
    *   For example, from a VM, you could connect directly using `mysql -h 10.10.0.5 ...`, where `10.10.0.5` is the internal IP in your VPC.
    *   All network traffic is securely routed through Google's backbone network to the Cloud SQL instance.

This approach is like creating a "private entrance" (PSC endpoint) to Cloud SQL inside your VPC, instead of building a "bridge" (PSA) that connects the entire VPC.

#### Comparison: PSA vs. PSC (for VPC-to-Cloud SQL Access)

| Feature | **Private Service Access (PSA)** | **Private Service Connect (PSC)** |
| :--- | :--- | :--- |
| **Connection Method** | **VPC Peering** | **Endpoint** |
| **IP Address** | Uses a reserved IP range (separate from your subnets) | **Uses an internal IP from your subnet** |
| **Network Management** | Requires managing peering routes and firewall rules | Managed like any other internal resource with firewall rules |
| **Flexibility** | Less flexible (VPC-to-VPC) | Highly flexible (per-service endpoint) |
| **IP Conflict Risk** | Potential for IP range conflicts with peered network | **No IP conflict risk** |

#### Why is PSC a More Modern Approach?

*   **Simplified IP Management**: It uses your VPC's native IP scheme, making it intuitive to manage.
*   **Simplified Network Policies**: PSC endpoints can be treated like regular VMs, making it easy to apply existing firewall rules and security policies.
*   **No IP Overlap Issues**: It inherently avoids the classic problem of IP range conflicts that can occur with VPC peering.
*   **Easier On-Premises Connectivity**: On-premises environments connected via VPN or Interconnect can easily access the PSC endpoint without complex custom route advertisements.

#### Summary

When private access from your VPC to Cloud SQL is needed, you have two valid options:

1.  **Using PSA**: Peer your VPC with the Google services VPC (the traditional method).
2.  **Using PSC**: Create an endpoint (an internal IP) in your VPC that points to Cloud SQL (the modern method).

Therefore, if Datastream uses PSC and your VPC also uses PSC to connect to Cloud SQL, **PSA is not needed at all.**

---

### References

The official Google Cloud documentation referenced to formulate this answer is as follows:

1.  **Overview of private connectivity options in Datastream**
    *   [https://cloud.google.com/datastream/docs/private-connectivity](https://cloud.google.com/datastream/docs/private-connectivity)
    *   This document explains that while Datastream supports both VPC Peering and Private Service Connect, PSC is the more recommended approach.

2.  **Configure connectivity using Private Service Connect**
    *   [https://cloud.google.com/datastream/docs/configure-connectivity-private-service-connect](https://cloud.google.com/datastream/docs/configure-connectivity-private-service-connect)
    *   This guide describes the specific procedures and required resources (like `Network Attachment`) for setting up PSC in Datastream.

3.  **Private Services Access**
    *   [https://cloud.google.com/vpc/docs/private-services-access](https://cloud.google.com/vpc/docs/private-services-access)
    *   This document provides a detailed explanation of the concepts and operational model of PSA (based on VPC Peering), which helps in understanding its differences from PSC.

### Q: Can Cloud Run or App Engine also use Private Service Connect (PSC) to securely access Cloud SQL for MySQL?

**A:**

Yes, absolutely. **Cloud Run and App Engine can use Private Service Connect (PSC) to securely and privately access Cloud SQL for MySQL.**

However, the connection method is slightly different from a GCE VM and requires an additional component called the **Serverless VPC Access Connector**.

---

#### Detailed Explanation: How Serverless Environments Integrate with PSC

Cloud Run and App Engine Standard run in a Google-managed serverless environment, outside of your VPC. For these services to access resources inside your VPC (including a PSC endpoint), they first need a "bridge" into your network. The **Serverless VPC Access Connector** serves as that bridge.

##### 1. Cloud Run and App Engine Standard Environment

Both of these services use the same mechanism.

**How it works:**

1.  **Create a PSC Endpoint**: First, as described previously, you create a PSC endpoint (a forwarding rule with an internal IP) in your VPC that points to the Cloud SQL instance.
2.  **Create a VPC Access Connector**: You create a Serverless VPC Access Connector in the same region as your VPC. This connector acts as a tunnel between the serverless environment and your VPC.
3.  **Attach the Connector to Your Service**: When deploying your Cloud Run or App Engine service, you configure it to use this VPC Access Connector.
4.  **Connect**: The code in your service can now connect directly to the internal IP address of the PSC endpoint.
    *   This traffic is routed through the VPC Access Connector into your VPC.
    *   Once inside the VPC, the traffic is securely routed through the PSC endpoint to the Cloud SQL instance.

**Connection Flow Summary:**
`Cloud Run/App Engine Standard` → `Serverless VPC Access Connector` → `Your VPC` → `PSC Endpoint (Internal IP)` → `Cloud SQL`

##### 2. App Engine Flexible Environment

The App Engine Flexible environment is different. Its services run as GCE VM instances **within your project's VPC**.

**How it works:**

*   Since the App Engine Flex application already exists inside your VPC, **no VPC Access Connector is needed**.
*   It can connect directly to the PSC endpoint's internal IP address, exactly like a standard GCE VM.

---

#### Architecture Comparison Summary

| Service | Connection Method | Key Components Required |
| :--- | :--- | :--- |
| **Cloud Run** | Indirect Connection | **Serverless VPC Access Connector** + PSC Endpoint |
| **App Engine Standard** | Indirect Connection | **Serverless VPC Access Connector** + PSC Endpoint |
| **App Engine Flexible** | **Direct Connection** | PSC Endpoint |
| **Compute Engine (GCE)** | **Direct Connection** | PSC Endpoint |

---

#### Why Use This Approach? (Advantages)

*   **Consistent Network Policy**: All private traffic to Cloud SQL (from VMs, serverless, etc.) can be centralized through a single PSC endpoint, allowing for consistent firewall and network policy management.
*   **Complete Privacy**: The Cloud SQL instance does not need a public IP address, and all traffic remains on Google's internal network, maximizing security.
*   **Avoids PSA Complexity**: Since it doesn't use VPC Peering (PSA), there are no concerns about IP range conflicts or complex peering route management.

#### Summary

Cloud Run and App Engine Standard can privately connect to Cloud SQL by first entering the VPC via a **Serverless VPC Access Connector** and then accessing a **PSC endpoint** created within the VPC. App Engine Flexible, being already inside the VPC, can connect directly to the PSC endpoint without a connector.

This architecture is one of the standard methods for modern serverless applications to communicate securely and efficiently with Google Cloud's managed database services.

---

### References

The official Google Cloud documentation supporting this answer includes:

1.  **Serverless VPC Access overview**
    *   [https://cloud.google.com/vpc/docs/serverless-vpc-access](https://cloud.google.com/vpc/docs/serverless-vpc-access)
    *   The core document explaining the concept of the VPC Access Connector and how it enables serverless environments to access VPC resources.

2.  **Connect to a VPC network from Cloud Run**
    *   [https://cloud.google.com/run/docs/configuring/connecting-vpc](https://cloud.google.com/run/docs/configuring/connecting-vpc)
    *   Guides on how to configure a Cloud Run service with a VPC Access Connector to access resources with internal IP addresses (including PSC endpoints).

3.  **Connect to an instance using Private Service Connect**
    *   [https://cloud.google.com/sql/docs/mysql/connect-private-service-connect](https://cloud.google.com/sql/docs/mysql/connect-private-service-connect)
    *   Details the process of creating the PSC endpoint within the VPC, which is the target the serverless service will ultimately connect to.

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