terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
  credentials = file(var.gcp_credentials_file)
}

# 啟用必要的 GCP APIs
resource "google_project_service" "container_api" {
  project = var.project_id
  service = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam_api" {
  project = var.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "logging_api" {
  project = var.project_id
  service = "logging.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "monitoring_api" {
  project = var.project_id
  service = "monitoring.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking_api" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry_api" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin_api" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# 建立自訂 VPC 網路
resource "google_compute_network" "tracing_vpc" {
  name                    = "tracing-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"

  depends_on = [
    google_project_service.compute_api
  ]
}

# 建立子網路
resource "google_compute_subnetwork" "tracing_subnet" {
  name          = "tracing-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.tracing_vpc.id

  # 啟用私有 Google 存取
  private_ip_google_access = true

  # 次要 IP 範圍給 GKE
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# 注意：移除 Service Networking Connection 以避免衝突
# 如果未來需要 Cloud SQL 私有連接，可以手動配置或使用現有連接

# 取得專案資訊以獲得正確的數字 ID
data "google_project" "current" {
  project_id = var.project_id
}

# 授權 GKE Autopilot 預設 Service Account Artifact Registry Reader 權限
resource "google_project_iam_member" "autopilot_artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  # 使用正確的數字 ID 格式
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    google_project_service.artifactregistry_api,
    google_container_cluster.primary
  ]
}

resource "google_project_iam_member" "autopilot_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    google_project_service.logging_api,
    google_container_cluster.primary
  ]
}

# 建立 GKE Autopilot 私有叢集
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  
  # 啟用 Autopilot 模式
  enable_autopilot = true
  deletion_protection = false
  
  # 使用自訂 VPC
  network    = google_compute_network.tracing_vpc.id
  subnetwork = google_compute_subnetwork.tracing_subnet.id

  # 私有集群設定
  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false  # 允許外部存取 API 端點
    master_ipv4_cidr_block = "172.16.0.0/28"
  }

  # 授權網路配置 - 允許所有 IP 存取（生產環境建議限制特定 IP）
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "all-for-deployment"
    }
  }

  # IP 分配策略 - 使用子網路的次要範圍
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  # 確保依賴關係正確
  depends_on = [
    google_project_service.container_api,
    google_project_service.compute_api,
    google_project_service.iam_api,
    google_compute_subnetwork.tracing_subnet
  ]
}

# Cloud SQL Proxy 相關資源

# 1. 建立專用 Service Account
resource "google_service_account" "cloudsql_sa" {
  account_id   = "cloudsql-proxy-sa"
  display_name = "Cloud SQL Proxy Service Account"

  depends_on = [
    google_project_service.iam_api
  ]
}

# 2. 給予 cloudsql.client 權限
resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudsql_sa.email}"

  depends_on = [
    google_project_service.sqladmin_api
  ]
}

# 3. 建立 Service Account Key
resource "google_service_account_key" "cloudsql_sa_key" {
  service_account_id = google_service_account.cloudsql_sa.name
}

# 4. 將金鑰寫入本地檔案
resource "local_file" "cloudsql_sa_key_json" {
  content  = base64decode(google_service_account_key.cloudsql_sa_key.private_key)
  filename = "${path.module}/.config/cloudsql/cloudsql-sa-key.json"

  # 確保目錄存在 - Windows 相容性
  provisioner "local-exec" {
    command = "powershell -Command \"New-Item -ItemType Directory -Force -Path '${path.module}/.config/cloudsql'\""
  }
}

# Kubernetes provider 已移除 - 應用部署由 scripts 處理
# 使用 gcloud 和 kubectl 進行 K8s 資源管理

# 建立 Graylog 區域靜態 IP（用於 LoadBalancer）
resource "google_compute_address" "graylog_ip" {
  name         = "graylog-static-ip"
  address_type = "EXTERNAL"
  region       = var.region
}

# 建立防火牆規則允許 Graylog 存取
# 建立 Cloud Router 給 NAT 使用
resource "google_compute_router" "tracing_router" {
  name    = "tracing-router"
  region  = var.region
  network = google_compute_network.tracing_vpc.id

  depends_on = [
    google_compute_network.tracing_vpc
  ]
}

# 建立 NAT 閣道，讓私有節點能存取外部網路
resource "google_compute_router_nat" "tracing_nat" {
  name                               = "tracing-nat"
  router                             = google_compute_router.tracing_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  depends_on = [
    google_compute_router.tracing_router
  ]
}

# 建立防火牆規則允許 Graylog 存取
resource "google_compute_firewall" "allow_graylog" {
  name    = "allow-graylog-access"
  network = google_compute_network.tracing_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["9000", "12201"]
  }

  allow {
    protocol = "udp"
    ports    = ["12201"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-${var.cluster_name}"]

  depends_on = [
    google_compute_network.tracing_vpc
  ]
}
