# FAQ

## Table of Contents

- [1. General Concepts & Setup](#1-general-concepts--setup)
  - [1.1. Q: Which GCP APIs need to be enabled before running `terraform apply`?](#11-q-which-gcp-apis-need-to-be-enabled-before-running-terraform-apply)
  - [1.2. Q: What is the relationship between VPC Peering and GCP managed services like Cloud SQL or Vertex AI?](#12-q-what-is-the-relationship-between-vpc-peering-and-gcp-managed-services-like-cloud-sql-or-vertex-ai)
  - [1.3. Q: What GCP resource does the `google_service_networking_connection` Terraform resource block create?](#13-q-what-gcp-resource-does-the-google_service_networking_connection-terraform-resource-block-create)
  - [1.4. Q: Where can I verify the VPC Peering for a private Cloud SQL connection?](#14-q-where-can-i-verify-the-vpc-peering-for-a-private-cloud-sql-connection)
  - [1.5. Q: How do firewall rules work in a private connectivity environment (PSA vs. PSC)?](#15-q-how-do-firewall-rules-work-in-a-private-connectivity-environment-psa-vs-psc)
- [2. Terraform & Resource Management](#2-terraform--resource-management)
  - [2.1. Q: When configuring Datastream and Cloud SQL replication, which resources should be created only once per project and shared?](#21-q-when-configuring-datastream-and-cloud-sql-replication-which-resources-should-be-created-only-once-per-project-and-shared)
  - [2.2. Q: If I have already created a `google_service_networking_connection` for another Cloud SQL instance (A), can I not create it again for a new instance (B)?](#22-q-if-i-have-already-created-a-google_service_networking_connection-for-another-cloud-sql-instance-a-can-i-not-create-it-again-for-a-new-instance-b)
  - [2.3. Q: When connecting Datastream and Cloud SQL via PSC, should a Network Attachment be created for each Cloud SQL instance, or just once?](#23-q-when-connecting-datastream-and-cloud-sql-via-psc-should-a-network-attachment-be-created-for-each-cloud-sql-instance-or-just-once)
  - [2.4. Q: What problems can occur if I create multiple Network Attachments?](#24-q-what-problems-can-occur-if-i-create-multiple-network-attachments)
- [3. Private Service Connect (PSC) Deep Dive](#3-private-service-connect-psc-deep-dive)
  - [3.1. Q: Is it necessary to enable Private Service Access (PSA) for Cloud SQL when connecting from Datastream using Private Service Connect (PSC)?](#31-q-is-it-necessary-to-enable-private-service-access-psa-for-cloud-sql-when-connecting-from-datastream-using-private-service-connect-psc)
  - [3.2. Q: If Private Service Access (PSA) isn't needed for Datastream with PSC, can a user in the VPC also connect to Cloud SQL securely using only PSC, without PSA?](#32-q-if-private-service-access-psa-isnt-needed-for-datastream-with-psc-can-a-user-in-the-vpc-also-connect-to-cloud-sql-securely-using-only-psc-without-psa)
  - [3.3. Q: If a PSC endpoint makes Cloud SQL accessible within the VPC, does that mean any resource in the VPC can connect automatically, or is a firewall rule still needed?](#33-q-if-a-psc-endpoint-makes-cloud-sql-accessible-within-the-vpc-does-that-mean-any-resource-in-the-vpc-can-connect-automatically-or-is-a-firewall-rule-still-needed)
  - [3.4. Q: What is the `google_compute_forwarding_rule` resource created for PSC? Is it a load balancer or a VM?](#34-q-what-is-the-google_compute_forwarding_rule-resource-created-for-psc-is-it-a-load-balancer-or-a-vm)
  - [3.5. Q: Can Cloud Run or App Engine also use Private Service Connect (PSC) to securely access Cloud SQL for MySQL?](#35-q-can-cloud-run-or-app-engine-also-use-private-service-connect-psc-to-securely-access-cloud-sql-for-mysql)
- [4. Datastream & Operations](#4-datastream--operations)
  - [4.1. Q: Is it mandatory to enable Private Service Connect (PSC) on a Cloud SQL for MySQL instance to connect to it from Datastream?](#41-q-is-it-mandatory-to-enable-private-service-connect-psc-on-a-cloud-sql-for-mysql-instance-to-connect-to-it-from-datastream)
  - [4.2. Q: When using PSC to connect to Cloud SQL, should the Datastream Source Connection Profile use the Cloud SQL private IP or the static IP from the forwarding rule?](#42-q-when-using-psc-to-connect-to-cloud-sql-should-the-datastream-source-connection-profile-use-the-cloud-sql-private-ip-or-the-static-ip-from-the-forwarding-rule)
  - [4.3. Q: What is the default value for `desired_state` in the `google_datastream_stream` resource?](#43-q-what-is-the-default-value-for-desired_state-in-the-google_datastream_stream-resource)
  - [4.4. Q: Considering Datastreams configuration, how are multiple databases and tables stored in BigQuery?](#44-q-considering-datastreams-configuration-how-are-multiple-databases-and-tables-stored-in-bigquery)
  - [4.5. Q: What is the `gcloud` command to start a Datastream Stream created by `terraform apply`?](#45-q-what-is-the-gcloud-command-to-start-a-datastream-stream-created-by-terraform-apply)

## 1. General Concepts & Setup

### 1.1. Q: Which GCP APIs need to be enabled before running `terraform apply`?

**A:**

Yes, certainly. Here is a step-by-step list of the APIs that need to be enabled in your GCP project before you run `terraform apply`.

For both stages to execute successfully, the APIs below must be **enabled in advance**.

#### Complete List of Required APIs

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

### 1.2. Q: What is the relationship between VPC Peering and GCP managed services like Cloud SQL or Vertex AI?

**A:**

The short answer is that you **do not use standard VPC Peering** to connect to Google-managed services like Cloud SQL or Vertex AI. Instead, you use a specialized mechanism called **Private Service Access (PSA)**, which is *built on top of* VPC Peering technology. For modern use cases, an alternative called **Private Service Connect (PSC)** is often preferred.

#### 1. The Problem: Where Do Managed Services Live?

Google's managed services (PaaS/SaaS) do not run inside your VPC. They run in a separate, Google-owned VPC. The challenge is to connect your VPC to this service VPC privately and securely.

#### 2. Solution 1: Private Service Access (PSA) - The Peering-Based Method

PSA establishes a **private, dedicated VPC Peering connection** between your VPC and the Google service's VPC.

*   **How it Works**:
    1.  You reserve an IP range in your VPC for Google services.
    2.  When you enable PSA, Google automatically creates a VPC Peering connection in the background.
    3.  Google assigns internal IPs from your reserved range to its managed services (e.g., your Cloud SQL instance).
*   **Result**: Your VMs can access the Cloud SQL instance using its new internal IP, and all traffic stays within Google's network.
*   **Key Takeaway**: You don't create the peering yourself; you enable PSA, and Google manages the peering for you.

#### 3. Solution 2: Private Service Connect (PSC) - The Modern Endpoint-Based Method

PSC is a newer, more flexible technology that does **not** use VPC Peering. Instead, it exposes the Google-managed service as a **private endpoint** directly inside your own VPC.

*   **How it Works**:
    1.  You create a PSC endpoint in your VPC.
    2.  This endpoint gets a **single internal IP address** from your VPC's own subnet.
    3.  This endpoint acts as a proxy, forwarding all traffic sent to it directly to the Google service.
*   **Advantages over PSA**:
    *   **No IP Overlap Issues**: Since it doesn't peer entire networks, there's no risk of IP address conflicts.
    *   **Simplified IP Management**: You only manage a single endpoint IP, not an entire reserved range.
    *   **More Secure**: It provides a one-way, inbound connection from your VPC to the service, preventing the service from initiating connections back into your network.

#### Comparison Summary

| Feature | Standard VPC Peering | Private Service Access (PSA) | Private Service Connect (PSC) |
| :--- | :--- | :--- | :--- |
| **Primary Use Case** | Connecting two of your own VPCs | **Connecting your VPC to a Google Service VPC** | **Exposing a Google Service as an endpoint in your VPC** |
| **Underlying Tech** | Peering | **VPC Peering** | Endpoint (Forwarding Rule) |
| **IP Management** | Manual, risk of overlap | Reserve an IP range | **Uses a single IP from your subnet** |
| **Recommendation** | For user-managed VPCs | For legacy or specific scenarios | **Generally recommended for new projects** |

---

### 1.3. Q: What GCP resource does the `google_service_networking_connection` Terraform resource block create?

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

### 1.4. Q: Where can I verify the VPC Peering for a private Cloud SQL connection?

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

### 1.5. Q: How do firewall rules work in a private connectivity environment (PSA vs. PSC)?

**A:**

This is a critical security question. Firewall rules are configured differently for Private Service Access (PSA) and Private Service Connect (PSC) because their underlying network models are different.

The most important principle is that **VPC firewall rules always control traffic entering or leaving *your* VPC**. You cannot create rules inside the Google-managed service's VPC.

#### 1. Firewall Rules with Private Service Access (PSA)

Since PSA is based on VPC Peering, you are controlling traffic between two networks. To allow a VM in your VPC to connect to a Cloud SQL instance, you need an **Egress (outbound) firewall rule**.

*   **Direction**: `Egress`
*   **Source**: The VM(s) that need to connect (best specified by a **network tag**, e.g., `database-client`).
*   **Destination**: The **reserved IP range** you allocated for PSA (e.g., `192.168.10.0/24`). You must target the entire range.
*   **Protocols / Ports**: The specific port for your database (e.g., `tcp:3306` for MySQL).

This rule says: "Allow traffic *leaving* our VPC, *from* our client VMs, *to* the IP range where our Cloud SQL instance lives."

#### 2. Firewall Rules with Private Service Connect (PSC)

PSC exposes the service as an endpoint *inside* your VPC. Think of this endpoint as another VM with an IP address. This gives you more intuitive control. You need an **Ingress (inbound) firewall rule** to allow traffic *to* the endpoint.

*   **Direction**: `Ingress`
*   **Source**: The VM(s) that need to connect (again, best specified by a **network tag**).
*   **Destination**: The PSC endpoint itself. You can target it by its **network tag** or, more specifically, by its **single internal IP address** (e.g., `10.10.0.5/32`).
*   **Protocols / Ports**: The specific service port (e.g., `tcp:3306`).

This rule says: "Allow traffic *coming into* our PSC endpoint, *from* our client VMs."

#### Comparison Summary

| Feature | Private Service Access (PSA) | Private Service Connect (PSC) |
| :--- | :--- | :--- |
| **Primary Rule Type** | **Egress** (from client to service) | **Ingress** (to the endpoint) |
| **Rule Destination** | The entire **reserved IP range** | The **single IP address** or **tag** of the endpoint |
| **Analogy** | Guarding the bridge out of your city | Guarding the front door of a specific office in your city |
| **Security Model** | Controls traffic between two networks | Treats the service endpoint like any other resource within your network |
| **Directionality** | Can be configured for bidirectional traffic | Strictly unidirectional (your VPC initiates connection to the service) |

Using PSC with Ingress rules is generally considered more secure and easier to manage because it aligns with the standard practice of controlling access to specific resources within your VPC, rather than managing traffic flows to an external network.

---

## 2. Terraform & Resource Management

### 2.1. Q: When configuring Datastream and Cloud SQL replication, which resources should be created only once per project and shared?

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

### 2.2. Q: If I have already created a `google_service_networking_connection` for another Cloud SQL instance (A), can I not create it again for a new instance (B)?

**A:**

That's correct. **You cannot create it again, and you don't need to.**

The `google_service_networking_connection` is like a "dedicated bridge" that **exists only once per VPC**. Once this bridge is built, all services belonging to that VPC share it.

#### Key Concept: One Bridge, Multiple Plots of Land

*   **`google_service_networking_connection` (The Dedicated Bridge)**: This resource is a single connection between one VPC and Google's services. If you've already created it for instance A, all Google services will continue to use that bridge.
*   **`google_compute_global_address` (IP Address Range, i.e., The Plot of Land)**: When you create a new Cloud SQL instance B, you reuse the existing "bridge" and simply **reserve a new "plot of land" (private IP address range)** on the other side.

#### Conclusion

In a single VPC, you create the `google_service_networking_connection` resource only once. When adding new Cloud SQL instances later, you only need to add a new `reserved_peering_ranges` to that existing connection. Therefore, it is correct that you "cannot create it again," and if it already exists, you must reuse it.

---

### 2.3. Q: When connecting Datastream and Cloud SQL via PSC, should a Network Attachment be created for each Cloud SQL instance, or just once?

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

### 2.4. Q: What problems can occur if I create multiple Network Attachments?

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

## 3. Private Service Connect (PSC) Deep Dive

### 3.1. Q: Is it necessary to enable Private Service Access (PSA) for Cloud SQL when connecting from Datastream using Private Service Connect (PSC)?

**A:**

No, it is **not necessary to enable Private Service Access (PSA)**.

The short answer is that PSC and PSA are **two different methods for private connectivity**. Datastream is designed to use PSC, which functions independently of PSA.

#### Detailed Explanation: Private Service Connect (PSC) vs. Private Service Access (PSA)

Understanding the difference between these two technologies is key. Both provide private connectivity, but they operate differently and have distinct use cases.

| Feature | **Private Service Access (PSA)** | **Private Service Connect (PSC)** |
| :--- | :--- | :--- |
| **Core Concept** | **VPC Peering** | **Service Endpoint** |
| **Connection Model** | **VPC-to-VPC Connection**<br>Connects your entire VPC to a Google services VPC. | **Service-to-VPC Connection**<br>Exposes a specific service (like a Cloud SQL instance) as an internal IP address inside your VPC. |
| **IP Management** | Requires you to **reserve** an IP range in your VPC. | Does not require a reserved IP range.<br>It consumes a single internal IP address from your VPC's own subnet. |
| **Analogy** | **A Private Bridge**<br>Builds a bridge connecting your city to the Google services city. | **A Private Entrance**<br>Creates a dedicated entrance for a specific partner (Cloud SQL) inside your own building. |
| **Key Resource** | `google_service_networking_connection` | `google_compute_network_attachment`<br>(Used by the service producer, consumed by a forwarding rule) |

#### Why Datastream Doesn't Need PSA

1.  **Datastream is a Service Consumer**: Datastream needs to connect to a specific published service (Cloud SQL). PSC is designed precisely for this service-centric connection model.

2.  **PSC's Connection Method**:
    *   The Cloud SQL instance acts as a "published service."
    *   Datastream accesses this published service through a **Network Attachment** created in your VPC.
    *   This process establishes a private path to the service itself, independent of the VPC-wide peering created by PSA. Therefore, building the PSA "bridge" is not required for this scenario.

#### Summary

*   **Private Service Access (PSA)** uses **VPC Peering** to connect your VPC to a Google services VPC.
*   **Private Service Connect (PSC)** exposes a specific service as a **private endpoint** inside your VPC.
*   Datastream uses **PSC** to connect to Cloud SQL.
*   Therefore, in a scenario where you are connecting Datastream to Cloud SQL via PSC, **you do not need to enable PSA**.

---

### 3.2. Q: If Private Service Access (PSA) isn't needed for Datastream with PSC, can a user in the VPC also connect to Cloud SQL securely using only PSC, without PSA?

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

Therefore, if Datastream uses PSC and your VPC also uses PSC to connect to Cloud SQL, **PSA is not needed at all**.

---

### 3.3. Q: If a PSC endpoint makes Cloud SQL accessible within the VPC, does that mean any resource in the VPC can connect automatically, or is a firewall rule still needed?

**A:**

That is an excellent and critical question. The short answer is: **No, resources cannot connect automatically. A firewall rule is absolutely necessary.**

While the PSC endpoint creates a private network *path*, it does not grant security *permission*. Access control is still fully managed by VPC firewall rules. This is a crucial security feature, not a limitation.

#### Why is a Firewall Rule Essential? (Think of the PSC Endpoint as a VM)

The easiest way to understand this is to treat the PSC endpoint (the forwarding rule with an internal IP) just like any other virtual machine in your VPC.

1.  **The PSC Endpoint Has an IP**: The endpoint is assigned a stable internal IP address (e.g., `10.10.0.5`) from your VPC's subnet.
2.  **Firewalls Inspect All Traffic**: GCP's VPC firewall inspects all traffic flowing to and from any resource with an IP address, including PSC endpoints.
3.  **Default-Deny Policy**: By default, VPCs have an "implied deny" rule for all ingress traffic. Unless you create a specific `ALLOW` rule, traffic from a GCE VM to the PSC endpoint's IP will be blocked.

This is the same principle as needing an `allow-ssh` rule to connect from one VM to another. To connect from a VM to the PSC endpoint on the MySQL port, you need a specific firewall rule to allow that traffic.

#### What Kind of Firewall Rule is Needed?

Following the principle of least privilege, you should create a specific **ingress `ALLOW` rule** that permits MySQL traffic (TCP port 3306) only from authorized sources to the PSC endpoint.

*   **Direction**: `INGRESS`
*   **Source**: The **network tag** of the GCE VMs that need access (e.g., `app-server`). Using tags is highly recommended over using IP ranges.
*   **Destination**: The most secure way to define the destination is to use the **destination IP range** field, setting it to the specific IP of your PSC endpoint (e.g., `10.10.0.5/32`).
*   **Protocols and Ports**: `tcp:3306`

##### Example `gcloud` Command

To allow VMs tagged with `app-server` to connect to the PSC endpoint at `10.10.0.5`, you would create a rule like this:

```bash
gcloud compute firewall-rules create allow-mysql-to-psc-endpoint \
    --network=your-vpc-name \
    --action=ALLOW \
    --direction=INGRESS \
    --rules=tcp:3306 \
    --source-tags=app-server \
    --destination-ranges=10.10.0.5/32 \
    --description="Allow MySQL traffic from app servers to the Cloud SQL PSC endpoint"
```
This rule ensures that only authorized VMs can access the database via its PSC endpoint, while all other traffic remains blocked.

#### Conclusion

Private Service Connect provides the **private network path**, but **VPC firewall rules** provide the **security and access control**. This separation of concerns is fundamental to a secure cloud architecture, allowing you to maintain fine-grained control over all resources, even those accessed via PSC.

---

### 3.4. Q: What is the `google_compute_forwarding_rule` resource created for PSC? Is it a load balancer or a VM?

**A:**

That's an excellent question, as the nature of this resource can be confusing.

The short answer is that the `google_compute_forwarding_rule` resource, in this context, is **neither a load balancer nor a VM.**

The most accurate analogy is a **"smart virtual entry point"** or a **"network endpoint"** that lives inside your VPC.

---

#### Detailed Explanation: The True Nature of a Forwarding Rule

Let's use a company building analogy to understand its role:

*   **Your VPC Network**: This is your company building.
*   **Cloud SQL Instance**: This is an important external partner you need to collaborate with.
*   **`google_compute_forwarding_rule`**: This is a **"dedicated reception desk for the partner"** that you set up on the first floor of your building.

This reception desk has the following characteristics:

1.  **It has a unique internal extension number (an internal IP address).**
    *   When the `forwarding_rule` is created, it is assigned an **internal IP address from your VPC's subnet** (e.g., `10.10.0.5`).
    *   Now, your employees (other resources in the VPC) don't need to know the partner's actual address; they just call this internal extension.

2.  **It doesn't do any work itself (Why it's not a VM).**
    *   This reception desk is not a computer with a CPU or memory. It doesn't process any tasks.
    *   Similarly, a `forwarding_rule` has no operating system or computing power. It's just a network address.

3.  **It doesn't distribute requests (Why it's not a Load Balancer).**
    *   A load balancer's job is to distribute incoming requests among multiple employees (backends).
    *   This reception desk, however, only forwards calls to **one specific, pre-assigned partner (the Cloud SQL instance)**. It's a 1-to-1 connection.
    *   While a `forwarding_rule` is technically a core component of a load balancer, in the context of PSC, it's used not for load distribution but to create a **single entry point** to a specific service.

#### Core Role Summary

The `google_compute_forwarding_rule` does one thing and one thing only:

> It takes all network traffic that arrives at its IP address (e.g., `10.10.0.5`) and **forwards it verbatim** to the single, pre-configured destination (the Cloud SQL instance specified in the `target` attribute).

This process creates the magical effect of making an external service like Cloud SQL appear as if it were a native resource inside your VPC.

#### Comparison Table

| Feature | Forwarding Rule (in PSC) | Internal Load Balancer | Virtual Machine (VM) |
| :--- | :--- | :--- | :--- |
| **Primary Role** | Forwards traffic to a single target | Distributes traffic to multiple backends | Executes applications |
| **IP Address** | **Yes (Core Function)** | Yes (Frontend IP) | Yes |
| **Compute Resources** | **No** | No (Manages backend VMs) | **Yes (CPU, Memory)** |
| **Backend Management** | **No (Single Target)** | **Yes (Backend Pool/Service)** | No (Is a backend) |

#### Conclusion

Therefore, the `google_compute_forwarding_rule` we are creating is not a VM or a load balancer. It is a lightweight, fully-managed network resource whose sole purpose is to **create a stable, private, internal IP address for the Cloud SQL instance inside your VPC**.

---

### 3.5. Q: Can Cloud Run or App Engine also use Private Service Connect (PSC) to securely access Cloud SQL for MySQL?

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

## 4. Datastream & Operations

### 4.1. Q: Is it mandatory to enable Private Service Connect (PSC) on a Cloud SQL for MySQL instance to connect to it from Datastream?

**A:**

Yes, that's correct. **To connect to a Cloud SQL for MySQL instance from Datastream using Private Service Connect (PSC), you must enable PSC on the target Cloud SQL instance.**

#### Why is this mandatory?

Private Service Connect operates on a "producer" and "consumer" model.

1.  **Service Producer**: This is the service being offered. In this scenario, **Cloud SQL for MySQL** is the producer. Enabling PSC on Cloud SQL creates a **Service Attachment**, which is an internal endpoint that exposes the service. This is equivalent to announcing, "Our service is ready to accept connections via PSC."

2.  **Service Consumer**: This is the service that uses the published service. In this case, **Datastream** is the consumer. When you configure a Private Connection in Datastream to use PSC, it looks for the Service Attachment published by Cloud SQL to establish a private link.

Therefore, if the Cloud SQL instance does not enable PSC to expose itself as a "service producer," Datastream will have no target to connect to, making a PSC connection impossible.

#### Official Documentation

This requirement is detailed in the official Google Cloud documentation:

1.  **About Private Service Connect for Cloud SQL**:
    *   This document explains the concept of enabling PSC on Cloud SQL to publish the instance as a service.
    *   **Link**: [https://cloud.google.com/sql/docs/mysql/private-service-connect](https://cloud.google.com/sql/docs/mysql/private-service-connect)

2.  **Configure a private connection for Datastream**:
    *   This guide for setting up a private connection from Datastream to a source presupposes that the source (Cloud SQL) has already been exposed via PSC.
    *   **Link**: [https://cloud.google.com/datastream/docs/configure-private-connectivity](https://cloud.google.com/datastream/docs/configure-private-connectivity)

In short, for Datastream to "knock on the door" of Cloud SQL via PSC, Cloud SQL must first "open the door" by enabling PSC.

---

### 4.2. Q: When using PSC to connect to Cloud SQL, should the Datastream Source Connection Profile use the Cloud SQL private IP or the static IP from the forwarding rule?

**A:**

That's an excellent question that gets to the core of the PSC architecture. It's an easy point of confusion, but the two connection paths are distinctly different.

The short answer is: **No. You must use the Cloud SQL instance's unique private IP for the Datastream Source Connection Profile.**

You should **not** use the static IP of the Forwarding Rule that was created for clients connecting from within your VPC.

Here’s a detailed explanation of why they are different and how each path works.

---

#### Detailed Explanation: Two Independent Connection Paths

In this architecture, there are two completely separate private paths to Cloud SQL: one for Datastream and one for clients inside your VPC.

##### Path 1: Datastream → Cloud SQL (Service-to-Service Connection)

This path is for one Google-managed service (Datastream) to connect to another (Cloud SQL).

1.  **Who is connecting?**: The Datastream service itself, which runs in Google's managed environment, outside of your VPC.
2.  **How does it access the VPC?**: Datastream uses a `PrivateConnection` resource, which secures a "connection point" to your VPC via a **`Network Attachment`**. The Network Attachment is not an IP address; it's a "gateway" or "dedicated entrance" that allows a specific service (Datastream) to enter your VPC.
3.  **How does it find Cloud SQL?**: Once connected to your VPC network via the Network Attachment, Datastream can directly resolve and route to the Cloud SQL instance's unique private IP address using Google's internal networking. This IP address belongs to the service networking range allocated via Private Services Access (PSA).
4.  **Conclusion**: Datastream has no knowledge of the Forwarding Rule you created, nor does it need any. It enters through the Network Attachment and then communicates directly with Cloud SQL's actual private IP.

##### Path 2: VPC Internal Client (e.g., GCE VM) → Cloud SQL (Client-to-Service Connection)

This path is for resources inside your VPC (like VMs or Cloud Run services) to connect to Cloud SQL.

1.  **Who is connecting?**: A GCE VM, a GKE Pod with an IP from your VPC subnet, or a serverless service connected via a VPC Access Connector.
2.  **What IP is needed?**: These clients need a destination IP address that is routable from within their own VPC subnet. Cloud SQL's unique private IP (in the PSA range) is not directly routable from within the VPC by default.
3.  **How does it connect?**: This is where the **Forwarding Rule** and its static IP are used.
    *   The Forwarding Rule creates an internal IP address (e.g., `10.10.0.5`) within your VPC's subnet.
    *   Clients inside the VPC send connection requests to this `10.10.0.5` address.
    *   The Forwarding Rule then transparently takes this request and forwards it through PSC to the actual Cloud SQL instance.
4.  **Conclusion**: To clients inside the VPC, Cloud SQL's actual private IP is invisible. They must use the static IP of the Forwarding Rule, which acts as a "representative" or "proxy" inside the VPC.

#### Comparison Summary

| Feature | Datastream Connection | VPC Internal Client Connection |
| :--- | :--- | :--- |
| **Connecting Entity** | Datastream Service (External to VPC) | GCE VM, Cloud Run, etc. (Internal to VPC) |
| **Network Entry Point** | Network Attachment | Forwarding Rule's IP Address |
| **IP Address to Use** | **Cloud SQL's unique private IP** | **Forwarding Rule's static internal IP** |
| **Purpose** | Data Replication (CDC) | Application Database Access |
| **Analogy** | A dedicated service entrance | A public-facing reception desk |

#### Final Summary

Therefore, you must use two different IP addresses for two different use cases:

*   **For the Datastream Source Connection Profile**: Use the actual private IP of the Cloud SQL instance (e.g., the output of `terraform output cloud_sql_instance_private_ip`).
*   **For applications/VMs inside your VPC**: Use the static internal IP of the Forwarding Rule (e.g., the output of `terraform output cloud_sql_psc_endpoint_ip`).

---

### References

The official Google Cloud documentation that supports this distinction is as follows:

1.  **Create a source connection profile for MySQL**
    *   [https://cloud.google.com/datastream/docs/create-a-source-connection-profile-for-mysql#create-a-connection-profile-for-mysql](https://cloud.google.com/datastream/docs/create-a-source-connection-profile-for-mysql#create-a-connection-profile-for-mysql)
    *   In the "Connectivity method" section, when "Private connectivity" is selected, the documentation specifies that you must enter the **private IP address of the Cloud SQL instance** in the "Hostname or IP address" field. This clearly shows that Datastream uses the instance's actual IP, not a forwarding rule.

2.  **Connect to an instance using Private Service Connect**
    *   [https://cloud.google.com/sql/docs/mysql/connect-private-service-connect](https://cloud.google.com/sql/docs/mysql/connect-private-service-connect)
    *   This document explains how clients (like a VM) connect via PSC. The "Connect using PSC" section shows that the client must connect to the **IP address of the forwarding rule**, which acts as the PSC endpoint.

---

### 4.3. Q: What is the default value for `desired_state` in the `google_datastream_stream` resource?

**A:**

According to the official Terraform documentation, the `desired_state` argument has **no explicit default value**.

However, if you **omit** this argument from your code, Terraform will not pass a `desired_state` value to the GCP API. In this case, following the default behavior of the GCP Datastream API, the Stream will be created in the **`NOT_STARTED`** state.

#### Behavior Summary by Scenario

| `desired_state` Setting | Terraform Action | Final Stream State |
| :--- | :--- | :--- |
| **Argument Omitted** | Does not include the `desired_state` field in the API call | **`NOT_STARTED`** |
| `desired_state = "RUNNING"` | Sets `desired_state` to "RUNNING" in the API call | `RUNNING` |
| `desired_state = "PAUSED"` | Sets `desired_state` to "PAUSED" in the API call | `PAUSED` |

Therefore, if you omit the `desired_state` line from your code, the Stream will be safely created in a `NOT_STARTED` state, allowing you to start it manually later.

---

### 4.4. Q: Considering Datastreams configuration, how are multiple databases and tables stored in BigQuery?

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

---

### 4.5. Q: What is the `gcloud` command to start a Datastream Stream created by `terraform apply`?

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
