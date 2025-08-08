# Terraform 및 PSC 관련 자주 묻는 질문 (FAQ)

---

### Q: Terraform의 `google_service_networking_connection` 리소스 블록이 생성하는 GCP 자원은 무엇인가요?

**A:**

`google_service_networking_connection` 리소스는 **내 VPC 네트워크**와 **Google이 관리하는 서비스(예: Cloud SQL)의 VPC 네트워크** 사이에 **비공개(private) 통신 통로**를 만드는 역할을 합니다.

이 통로를 기술적으로 **VPC 네트워크 피어링(VPC Network Peering)** 이라고 부릅니다.

#### 쉬운 비유: 전용 다리(Private Bridge)

이 개념을 쉽게 이해하기 위해 비유를 들어보겠습니다.

*   **내 VPC 네트워크**: 내가 소유한 '우리 도시'입니다. 이 안에는 내 가상 머신(VM)이나 다른 서비스들이 살고 있습니다.
*   **Google 서비스의 VPC 네트워크**: Google이 소유하고 관리하는 'Google 서비스 도시'입니다. 이 도시에는 Cloud SQL, Memorystore 같은 Google의 관리형 서비스들이 살고 있습니다.
*   **`google_service_networking_connection`**: '우리 도시'와 'Google 서비스 도시'를 연결하는 **비공개 전용 다리**입니다.

이 다리가 없으면, '우리 도시'의 서비스가 'Google 서비스 도시'의 Cloud SQL에 접근하려면 공용 인터넷이라는 외부 도로를 이용해야 합니다. 하지만 이 전용 다리를 놓으면, 외부로 나가지 않고도 두 도시 간에 안전하고 빠르게 직접 통신할 수 있게 됩니다.

#### 코드와 실제 자원의 매핑

`main.tf` 파일에 있는 코드 블록이 이 '전용 다리'를 어떻게 만드는지 살펴보겠습니다.

```terraform
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.main_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [...] 
}
```

*   `network`: '전용 다리'의 출발점, 즉 **내 VPC 네트워크**를 지정합니다.
*   `service`: '전용 다리'의 도착점, 즉 **Google의 관리형 서비스들이 모여있는 도시**로 연결됩니다.
*   `reserved_peering_ranges`: 가장 중요한 부분으로, 'Google 서비스 도시'에서 내 Cloud SQL 인스턴스가 사용할 **비공개 IP 주소 범위를 예약**하는 역할을 합니다. "다리가 연결되면, Google 쪽에 내 Cloud SQL이 살 집(IP 주소)을 이 범위 안에서 만들어 주세요." 라고 알려주는 것입니다.

#### 핵심 목적

1.  **비공개 IP 통신**: 내 VPC의 리소스들이 Cloud SQL 인스턴스의 공개 IP가 아닌 비공개 IP를 사용하여 통신할 수 있게 합니다.
2.  **보안 강화**: 데이터베이스를 공용 인터넷에 노출할 필요가 없어 보안이 크게 향상됩니다.
3.  **네트워크 간소화**: 복잡한 방화벽이나 VPN 설정 없이 Google 관리형 서비스를 내 VPC 안에 있는 것처럼 쉽게 사용할 수 있습니다.

결론적으로, 이 리소스는 내 인프라와 Google의 관리형 서비스를 안전하고 효율적으로 통합하기 위한 필수적인 "네트워크 다리"입니다.

---

### Q: 만약 `google_service_networking_connection`을 다른 Cloud SQL 인스턴스(A)를 위해 이미 만들었다면, 새로 만들 인스턴스(B)를 위해 다시 만들 수 없나요?

**A:**

네, 정확합니다. **다시 만들 수 없으며, 만들 필요도 없습니다.**

`google_service_networking_connection`은 **VPC당 하나만 존재**하는 "전용 다리"와 같습니다. 이 다리는 한 번 건설하면 그 VPC에 속한 모든 서비스가 공유해서 사용합니다.

#### 핵심 개념: 다리는 한 번만, 집터는 여러 개

*   **`google_service_networking_connection` (전용 다리)**: 이 리소스는 1개의 VPC와 Google 서비스 간의 단일 연결입니다. 이미 인스턴스 A를 위해 만들었다면, 그 다리를 모든 Google 서비스가 계속 사용합니다.
*   **`google_compute_global_address` (IP 주소 범위, 즉 집터)**: 새로운 Cloud SQL 인스턴스 B를 만들 때는, 이미 놓인 "다리"를 재사용하고, 그 건너편에 **새로운 "집터"(비공개 IP 주소 범위)만 추가로 예약**하면 됩니다.

#### 결론

하나의 VPC에서는 `google_service_networking_connection` 리소스를 단 한 번만 생성하고, 이후 새로운 Cloud SQL 인스턴스를 추가할 때는 해당 연결에 새로운 `reserved_peering_ranges`만 추가하여 업데이트해야 합니다. 따라서 이 리소스를 "다시 만들 수 없는 것"이 맞으며, 이미 존재한다면 그것을 재사용해야 합니다.

---

### Q: Datastream과 Cloud SQL을 PSC 방식으로 연결할 때, Network Attachment는 연결하려는 Cloud SQL 인스턴스마다 각각 생성해야 하나요, 아니면 한 번만 생성해야 하나요?

**A:**

결론부터 말씀드리면, **Network Attachment는 한 번만 생성하면 됩니다.**

연결하려는 Cloud SQL 인스턴스마다 각각 생성할 필요가 없습니다.

#### 왜 한 번만 생성하면 될까요? (역할 비유)

Network Attachment의 역할을 '**Google 서비스 전용 출입구**'에 비유할 수 있습니다.

*   **내 VPC 네트워크**: 외부와 격리된 '우리 회사 건물'입니다.
*   **Network Attachment**: '우리 회사 건물'에 만든 **'Google 서비스 전용 출입구'** 입니다. 이 출입구는 Datastream, Vertex AI 등 PSC를 지원하는 모든 Google 서비스가 우리 건물로 들어올 때 사용하는 공식 통로입니다.
*   **Cloud SQL 인스턴스들 (A, B, C...)**: 우리 건물과 협업해야 하는 외부의 '파트너사 사무실'들입니다.

새로운 파트너사(Cloud SQL 인스턴스)가 생길 때마다 우리 회사 건물의 출입구를 새로 만들 필요가 없는 것과 같은 원리입니다.

#### 기술적 설명

*   **Network Attachment의 범위**: `google_compute_network_attachment` 리소스는 특정 Cloud SQL 인스턴스가 아닌, **VPC 네트워크**와 **리전(Region)** 에 종속됩니다.
*   **연결 흐름**: Datastream과 같은 서비스는 이 Network Attachment를 통해 소비자의 VPC로 진입한 후, PSC 인프라를 통해 목표하는 특정 Cloud SQL 인스턴스로 라우팅됩니다.

#### 결론

**하나의 VPC 네트워크**와 **하나의 리전** 조합에는 **하나의 Network Attachment**만 있으면 충분합니다. 해당 VPC/리전 내에서 여러 개의 Cloud SQL 인스턴스에 연결하고 싶다면, 이미 만들어 둔 Network Attachment 하나를 모든 연결이 공유해서 사용하게 됩니다.

---

### Q: 만약 Network Attachment를 여러 개 만들게 되면 어떤 문제가 발생할 수 있나요?

**A:**

기술적으로는 동작할 수 있지만, 여러 가지 관리적, 비용적, 잠재적 성능 문제를 야기합니다.

1.  **불필요한 비용 발생**: Network Attachment는 시간당 요금이 부과되는 리소스입니다. 여러 개를 만들면 사용하지 않는 Attachment에 대해서도 불필요한 비용을 계속 지불하게 됩니다.

2.  **관리의 복잡성 증가 (가장 큰 문제)**:
    *   **혼란스러운 아키텍처**: "어떤 서비스가 어떤 Attachment를 사용하지?"라는 혼란이 발생하여 장애 발생 시 원인 파악이 어려워집니다.
    *   **Terraform 코드 중복**: 거의 동일한 리소스 블록이 여러 개 존재하게 되어 코드 가독성을 해치고 유지보수를 어렵게 만듭니다.
    *   **방화벽 규칙 복잡성**: 각 Attachment마다 별도의 서브넷과 방화벽 규칙을 관리해야 하므로 보안 정책이 복잡해지고 실수의 가능성이 커집니다.

3.  **리소스 할당량(Quota) 문제**: GCP의 모든 리소스에는 할당량이 있습니다. 불필요하게 여러 개를 생성하면, 나중에 정말 필요한 Attachment를 만들지 못하는 상황이 발생할 수 있습니다.

4.  **잠재적인 성능 및 라우팅 문제**: 불필요하게 복잡한 네트워크 구성은 트래픽이 비효율적인 경로로 흐를 가능성을 만들고, 미세한 지연 시간(latency) 증가로 이어질 수 있습니다. 또한 문제 발생 시 디버깅이 훨씬 더 복잡해집니다.

#### 결론

Network Attachment를 여러 개 만드는 것은 **하나의 건물에 목적지가 같은 여러 개의 현관문을 불필요하게 만드는 것**과 같습니다. **"1 VPC, 1 Region, 1 Network Attachment"** 원칙을 지키는 것이 비용, 관리, 성능 모든 측면에서 가장 효율적이고 올바른 아키텍처 설계입니다.

---

### Q: `google_datastream_stream` 리소스에서 `desired_state`의 기본값은 무엇인가요?

**A:**

Terraform 공식 문서에 따르면 `desired_state` 인수의 **명시적인 기본값(Default Value)은 없습니다.**

하지만 이 인수를 코드에서 **생략할 경우**, Terraform은 GCP API에 `desired_state` 값을 전달하지 않습니다. 이 경우 GCP Datastream API의 기본 동작에 따라, Stream은 **`NOT_STARTED`** 상태로 생성됩니다.

#### 시나리오별 동작 요약

| `desired_state` 설정 | Terraform 동작 | 최종 Stream 상태 | 설명 |
| :--- | :--- | :--- | :--- |
| **인수 생략 (Omitted)** | API 호출 시 `desired_state` 필드를 포함하지 않음 | **`NOT_STARTED`** | **(GCP API의 기본 동작)** 리소스는 생성되지만, 데이터 복제는 시작되지 않은 상태입니다. |
| `desired_state = "RUNNING"` | API 호출 시 `desired_state`를 "RUNNING"으로 설정 | `RUNNING` | 리소스 생성 후 즉시 스트림을 시작하여 데이터 복제를 개시합니다. |
| `desired_state = "PAUSED"` | API 호출 시 `desired_state`를 "PAUSED"으로 설정 | `PAUSED` | 리소스 생성 후 즉시 스트림을 일시 중지 상태로 둡니다. |

따라서 코드에서 `desired_state` 라인을 생략하면, Stream이 `NOT_STARTED` 상태로 안전하게 생성되어 나중에 수동으로 시작할 수 있습니다.

---

### Q: Datastream의 구성을 고려했을 때, 여러 개의 데이터베이스와 테이블이 BigQuery에 어떤 식으로 저장되나요?

**A:**

Datastream은 소스(MySQL)의 **계층 구조(Hierarchy)**를 목적지(BigQuery)에서도 그대로 유지해 줍니다.

*   **MySQL의 계층**: `데이터베이스(스키마) → 테이블`
*   **BigQuery의 계층**: `프로젝트 → 데이터세트(Dataset) → 테이블`

Datastream은 MySQL의 `데이터베이스`를 BigQuery의 `데이터세트`에, MySQL의 `테이블`을 BigQuery의 `테이블`에 매핑하여 이 구조를 보존합니다.

#### 저장 방식: `source_hierarchy_datasets` 설정

이 동작은 `google_datastream_stream` 리소스의 `bigquery_destination_config` 블록 안에 있는 **`source_hierarchy_datasets`** 설정으로 제어됩니다.

```terraform

destination_config {
  bigquery_destination_config {
    source_hierarchy_datasets {
      dataset_template {
        location = var.bigquery_dataset_location
        dataset_id_prefix = "my_cdc_data" // 예시 접두사
      }
    }
  }
}
```

#### 구체적인 저장 예시

만약 소스 MySQL에 `sales_db`와 `inventory_db` 데이터베이스가 있다면, BigQuery에는 다음과 같은 구조로 데이터세트와 테이블이 생성됩니다.

*   **`my_cdc_data_sales_db`** (데이터세트)
    *   `customers` (테이블)
    *   `orders` (테이블)
*   **`my_cdc_data_inventory_db`** (데이터세트)
    *   `products` (테이블)

**규칙 요약:**
> BigQuery 데이터세트 이름 = **`[dataset_id_prefix]_[소스_데이터베이스_이름]`**

이 방식을 통해 소스의 논리적 구분이 BigQuery에서도 그대로 유지되어 데이터를 식별하고 관리하기가 매우 쉬워집니다.

#### BigQuery 테이블의 추가 메타데이터

BigQuery에 생성된 각 테이블에는 소스 테이블의 모든 컬럼과 더불어, Datastream이 추가하는 유용한 **메타데이터 컬럼**이 포함됩니다.

| 메타데이터 컬럼 | 설명 |
| :--- | :--- |
| `datastream_metadata.uuid` | 각 행의 고유 식별자입니다. |
| `datastream_metadata.source_timestamp` | 소스에서 변경이 발생한 실제 시간입니다. |
| `datastream_metadata.is_deleted` | 소스에서 행이 `DELETE`되었는지 여부를 나타내는 `BOOLEAN` 값입니다 (Soft-delete). |

이 메타데이터를 활용하면 시간 기반의 정교한 데이터 분석이 가능해집니다.

---

### Q: `datastream` 사용자에게 필요한 권한을 모두 부여했는데도, Stream이 GTID 기반이 아닌 바이너리 로그 위치(Binary Log Position) 방식으로 동작합니다. 원인과 해결책은 무엇인가요?

**A:**

권한을 올바르게 부여했는데도 문제가 지속된다면, 원인은 단순한 설정 오류가 아닐 가능성이 높습니다. 가장 유력한 원인부터 순서대로 진단하고 해결해야 합니다.

#### 가장 유력한 원인: 기존 스트림의 "상태 기억"

Datastream은 Stream을 **처음 만들거나 검증하는 시점**의 소스 데이터베이스 설정을 기억합니다. 만약 그 시점에 권한이 부족했다면, Datastream은 안전한 방식인 '바이너리 로그 위치'를 사용하도록 결정하고 이 상태를 저장합니다. 이후에 권한을 부여하더라도, 이미 생성된 Stream은 이 결정을 자동으로 바꾸지 않을 수 있습니다.

**해결책 1: 스트림 재검증 또는 재생성 (가장 먼저 시도할 것)**

1.  **기존 스트림 삭제 (가장 확실한 방법)**: 문제가 있는 스트림을 GCP 콘솔이나 `gcloud` 명령어로 삭제합니다.
    ```bash
    gcloud datastream streams delete [STREAM_NAME] --location=[REGION]
    ```
2.  **Terraform으로 스트림 재생성**: `terraform apply`를 다시 실행하여 모든 권한이 준비된 상태에서 스트림을 깨끗하게 새로 만듭니다.

#### 다음 유력한 원인: GTID 비호환 트랜잭션 존재

`enforce_gtid_consistency=ON` 플래그는 **새로운** 비호환 트랜잭션을 막지만, 바이너리 로그에 **이미 기록된** 비호환 트랜잭션이 있다면 Datastream은 GTID 모드 사용을 거부할 수 있습니다.

**해결책 2: 비호환 트랜잭션 확인**

Cloud SQL 인스턴스에 접속하여 `SELECT @@GLOBAL.gtid_executed;` 쿼리를 실행합니다. 결과에 `ANONYMOUS` 라는 단어가 포함되어 있다면 GTID가 제대로 사용되지 않고 있는 것입니다. 이 경우, 데이터베이스를 새로 프로비저닝하고 데이터를 마이그레이션하는 것이 가장 간단한 해결책일 수 있습니다.

#### 최종 진단 방법: Datastream 로그 분석

위 방법으로 해결되지 않으면, **로그 탐색기(Logs Explorer)**에서 Datastream Stream 관련 로그를 직접 확인해야 합니다. 로그에는 "GTID를 사용할 수 없어 바이너리 로그 위치 방식으로 폴백합니다" 와 같이 실패 원인이 명시적으로 기록되어 있을 가능성이 높습니다.

**종합 해결 전략:**
1.  **(필수) 기존 Datastream Stream을 삭제합니다.**
2.  Cloud SQL 인스턴스에 접속하여 `GRANT` 구문이 올바르게 적용되었는지 다시 확인합니다.
3.  `terraform apply`를 실행하여 **새로운 Stream**을 생성합니다.
4.  생성된 새 스트림이 여전히 바이너리 로그 방식을 사용한다면, 즉시 **로그 탐색기**에서 원인을 확인합니다.

---

### Q: `terraform apply`로 생성된 Datastream Stream을 시작하는 `gcloud` 명령어는 무엇인가요?

**A:**

`terraform apply`로 생성된 `NOT_STARTED` 상태의 Datastream Stream을 시작하는 `gcloud` 명령어는 다음과 같습니다.

#### 기본 명령어

```bash
gcloud datastream streams update [STREAM_NAME] \
    --location=[REGION] \
    --state=RUNNING
```

*   **`[STREAM_NAME]`**: 시작하려는 Datastream Stream의 이름입니다. (Terraform 변수: `var.stream_name`)
*   **`[REGION]`**: Stream이 생성된 GCP 리전입니다. (Terraform 변수: `var.region`)
*   **`--state=RUNNING`**: Stream의 목표 상태를 '실행 중'으로 설정하는 핵심 부분입니다.

#### 예시

Stream 이름이 `mysql-to-bigquery-stream`이고 리전이 `us-central1`이라면, 아래와 같이 실행합니다.

```bash
gcloud datastream streams update mysql-to-bigquery-stream \
    --location=us-central1 \
    --state=RUNNING
```

#### 추가 옵션: `--force`

유효성 검사에서 경고가 발생하더라도 강제로 시작하고 싶다면 `--force` 플래그를 추가할 수 있습니다. 단, 경고의 내용을 충분히 이해하고 사용해야 합니다.

---

### Q: Cloud SQL을 private 하게 연결하기 위한 VPC Peering은 어디서 확인할 수 있는지?

**A:**

네, 아주 좋은 질문입니다. Cloud SQL의 비공개 IP 연결에 사용되는 VPC Peering은 일반적인 VPC Peering과는 약간 다른 방식으로 관리되며, 확인하는 위치도 정해져 있습니다.

결론부터 말씀드리면, **일반 VPC 네트워크 피어링 페이지에서 확인**하는 것이 맞지만, **Google이 관리하는 특별한 피어링 연결**을 찾아야 합니다.

--- 

#### Cloud SQL 비공개 연결의 원리 (Private Services Access)

먼저 원리를 간단히 이해하면 쉽습니다.

*   사용자가 Cloud SQL 인스턴스를 '비공개 IP'로 생성하면, Google은 내부적으로 **Google 소유의 VPC 네트워크**에 해당 SQL 인스턴스를 프로비저닝합니다.
*   그리고 사용자의 VPC와 Google 소유의 VPC 간에 **VPC 네트워크 피어링**을 자동으로 설정합니다.
*   이 메커니즘을 **'비공개 서비스 액세스(Private Services Access)'**라고 부릅니다.

따라서 우리가 찾아야 할 것은 내 프로젝트의 VPC와 Google의 서비스 VPC 간의 피어링 연결입니다.

--- 

#### 확인 방법

##### 1. Google Cloud Console (웹 UI)에서 확인

1.  Google Cloud Console에 로그인합니다.
2.  **탐색 메뉴(☰)** > **VPC 네트워크** > **VPC 네트워크 피어링**으로 이동합니다.
3.  표에서 다음과 같은 특징을 가진 피어링 연결을 찾습니다.

    *   **이름 (Name)**: `servicenetworking-googleapis-com`
    *   **피어링된 프로젝트 ID (Peer project ID)**: `servicenetworking` 또는 다른 Google 소유의 프로젝트 ID
    *   **상태 (State)**: `활성 (ACTIVE)` 이어야 합니다.

    *   **`servicenetworking-googleapis-com`** 이라는 이름의 연결이 바로 Cloud SQL, Memorystore 등 Google 관리형 서비스와의 비공개 연결을 위한 VPC Peering입니다.
    *   **상태가 `활성`**이라면, 내 VPC와 Cloud SQL이 있는 Google 서비스 VPC 간의 네트워크 경로가 성공적으로 구축되었음을 의미합니다.

##### 2. `gcloud` CLI (명령줄 도구)에서 확인

터미널에서 다음 명령어를 실행하여 확인할 수도 있습니다.

```bash
gcloud compute networks peerings list --network=[YOUR_VPC_NAME]
```

*   `[YOUR_VPC_NAME]`을 실제 사용하고 있는 VPC 네트워크 이름으로 바꿔주세요.

**실행 결과 예시:**

```
NAME: servicenetworking-googleapis-com
NETWORK: default
PEER_PROJECT: servicenetworking
STATE: ACTIVE
STATE_DETAILS: [OK]
```

위와 같이 `servicenetworking-googleapis-com` 피어링이 `ACTIVE` 상태로 나타나면 정상적으로 연결된 것입니다.

#### 요약

| 항목 | 내용 |
| :--- | :--- |
| **확인 위치** | **VPC 네트워크 > VPC 네트워크 피어링** 페이지 |
| **찾아야 할 이름** | `servicenetworking-googleapis-com` |
| **핵심 개념** | 비공개 서비스 액세스 (Private Services Access) |
| **정상 상태** | `활성 (ACTIVE)` |

---

### Q: Datastream, Cloud SQL Replication 구성 시, 프로젝트별로 한 번만 생성해서 공유해야 하는 리소스는 무엇인가요?

**A:**

네, 제공해주신 Terraform 코드를 분석하여 **GCP 프로젝트별로 한 번만 생성해서 공유해야 하는 리소스 목록**을 정리해 드리겠습니다.

이러한 리소스들은 보통 특정 네트워크나 서비스 간의 "연결" 또는 "설정" 역할을 하며, 여러 개의 데이터 파이프라인이나 인스턴스가 이 공유된 인프라를 함께 사용하게 됩니다.

---

#### 프로젝트별 공유 리소스 목록 및 설명

##### 1. `google_service_networking_connection`

*   **리소스 이름**: `private_vpc_connection`
*   **역할**: 사용자의 VPC와 Google 관리형 서비스(Cloud SQL 등)의 VPC를 연결하는 **VPC 네트워크 피어링**을 생성합니다.
*   **공유 이유**: 이 연결은 **VPC 네트워크당 하나만** 존재할 수 있습니다. 일단 생성되면, 해당 VPC 내의 모든 리소스가 이 단일 연결을 통해 Cloud SQL과 같은 서비스에 비공개로 접근합니다. 여러 개의 Cloud SQL 인스턴스를 만들더라도 이 연결은 하나만 사용됩니다.
*   **비유**: '우리 도시(내 VPC)'와 'Google 서비스 도시'를 잇는 **단 하나의 비공개 전용 다리**와 같습니다.

##### 2. `google_compute_global_address`

*   **리소스 이름**: `private_ip_address`
*   **역할**: 위에서 설명한 '서비스 네트워킹 연결'을 통해 Cloud SQL 인스턴스에 할당될 **비공개 IP 주소 범위를 예약**합니다.
*   **공유 이유**: `google_service_networking_connection`이 VPC당 하나만 존재하므로, 이 연결에 IP 범위를 예약하는 작업도 중앙에서 관리되어야 합니다. 만약 여러 파이프라인이 각자 다른 IP 범위를 이 연결에 추가하려고 하면 충돌이 발생할 수 있습니다. 따라서, 이 리소스는 **하나의 `google_service_networking_connection`에 대해 한 번만 생성**하고, 여러 Cloud SQL 인스턴스가 필요할 경우 이 예약된 범위 내에서 IP를 할당받도록 구성하는 것이 일반적입니다.
    *   *(고급: 물론 여러 개의 예약 범위를 가질 수는 있지만, 관리를 위해 중앙에서 하나의 Terraform 코드로 관리하는 것이 가장 좋습니다.)*

##### 3. `google_compute_network_attachment`

*   **리소스 이름**: `ds_to_sql_attachment`
*   **역할**: PSC(Private Service Connect)를 통해 Datastream과 같은 외부 서비스가 내 VPC로 들어올 수 있도록 **'네트워크 연결 지점'**을 생성합니다.
*   **공유 이유**: 이 리소스는 **VPC 네트워크와 리전(Region)의 조합당 하나만** 있으면 충분합니다. 일단 생성되면, 해당 VPC와 리전으로 들어오는 모든 PSC 기반 서비스(Datastream, Vertex AI 등)가 이 단일 연결 지점을 공유하여 사용합니다.
*   **비유**: '우리 회사 건물(내 VPC)'에 만든 **'Google 서비스 전용 출입구'**와 같습니다.

##### 4. `google_compute_subnetwork` (PSC용)

*   **리소스 이름**: `datastream_psc_subnet`
*   **역할**: 위의 `google_compute_network_attachment`가 사용할 **전용 서브넷**을 생성합니다.
*   **공유 이유**: Network Attachment가 공유 리소스이므로, 이 Attachment가 사용하는 서브넷 역시 공유됩니다. 이 서브넷은 PSC 연결을 위한 전용 공간으로, 다른 VM이나 서비스가 사용하지 않도록 격리하는 역할을 합니다.

---

#### 요약 표

| 리소스 타입 | Terraform 리소스 이름 | 공유 범위 | 왜 공유해야 하는가? |
| :--- | : | : | : |
| `google_service_networking_connection` | `private_vpc_connection` | VPC 네트워크 | VPC당 하나만 생성 가능. 모든 비공개 서비스 액세스를 위한 단일 통로. |
| `google_compute_global_address` | `private_ip_address` | 서비스 네트워킹 연결 | 위 연결에 대한 IP 예약이므로 중앙에서 관리해야 충돌 방지. |
| `google_compute_network_attachment` | `ds_to_sql_attachment` | VPC 네트워크 + 리전 | 해당 VPC/리전으로 들어오는 모든 PSC 서비스가 공유하는 단일 진입점. |
| `google_compute_subnetwork` | `datastream_psc_subnet` | Network Attachment | 위 Network Attachment가 사용하는 전용 서브넷이므로 함께 공유됨. |

---

### Q: `terraform apply`를 수행하기 전에 어떤 GCP API를 활성화해야 하나요?

**A:**

네, 그럼요. `terraform apply`를 실행하기 전에 GCP 프로젝트에서 활성화해야 하는 API 목록을 단계별로 정리해 드리겠습니다.

두 단계를 모두 성공적으로 실행하려면 아래 API들이 **미리 활성화**되어 있어야 합니다.

#### 필수 API 전체 목록

아래는 이 프로젝트의 모든 리소스를 생성하는 데 필요한 전체 API 목록입니다.

1.  **Compute Engine API**: `compute.googleapis.com`
    *   **용도**: VPC, 서브넷, 방화벽 규칙, Cloud Router, Cloud NAT, 네트워크 연결(Network Attachment) 등 모든 네트워킹 리소스를 생성하고 관리합니다.
    *   **필요 단계**: `01-network`, `02-app-infra`

2.  **Service Networking API**: `servicenetworking.googleapis.com`
    *   **용도**: Cloud SQL 인스턴스가 VPC와 비공개로 통신할 수 있도록 VPC 피어링을 설정합니다.
    *   **필요 단계**: `01-network`

3.  **Cloud SQL Admin API**: `sqladmin.googleapis.com`
    *   **용도**: Cloud SQL for MySQL 인스턴스와 사용자를 생성하고 관리합니다.
    *   **필요 단계**: `02-app-infra`

4.  **Datastream API**: `datastream.googleapis.com`
    *   **용도**: Datastream 비공개 연결, 연결 프로필, 스트림 리소스를 생성하고 관리합니다.
    *   **필요 단계**: `02-app-infra`

5.  **BigQuery API**: `bigquery.googleapis.com`
    *   **용도**: Datastream의 대상이 될 BigQuery 데이터 세트와 연결 프로필을 생성하고 관리합니다.
    *   **필요 단계**: `02-app-infra`

6.  **Cloud Resource Manager API**: `cloudresourcemanager.googleapis.com`
    *   **용도**: Terraform이 프로젝트의 리소스를 조회하고 관리하는 데 필요하며, 일반적으로 활성화되어 있는 경우가 많습니다.

#### API 활성화를 위한 `gcloud` 명령어

가장 편리한 방법은 Cloud Shell 또는 로컬에 `gcloud` CLI가 설치된 환경에서 아래 명령어를 실행하여 모든 필수 API를 한 번에 활성화하는 것입니다.

```bash

# 아래 명령어를 실행하여 필요한 모든 API를 활성화합니다.
# your-gcp-project-id를 실제 프로젝트 ID로 변경하세요.

gcloud services enable \
    compute.googleapis.com \
    servicenetworking.googleapis.com \
    sqladmin.googleapis.com \
    datastream.googleapis.com \
    bigquery.googleapis.com \
    cloudresourcemanager.googleapis.com \
    --project=your-gcp-project-id
```

이 명령어를 먼저 실행하시면, `terraform apply` 과정에서 API 활성화 관련 오류 없이 원활하게 리소스를 생성할 수 있습니다.