# OpenTelemetry 相關的 GCP 資源配置
# 注意：Kubernetes 資源（namespaces, service accounts, deployments）由 scripts 處理

# 建立 GCP 服務帳戶用於 OpenTelemetry Collector
resource "google_service_account" "otel_collector" {
  account_id   = "otel-collector"
  display_name = "OpenTelemetry Collector Service Account"
  description  = "Service account for OpenTelemetry Collector to export data to GCP"

  depends_on = [
    google_project_service.iam_api
  ]
}

# 注意：以下資源由 scripts/deploy-all.sh 處理：
# - Kubernetes namespaces (opentelemetry, graylog)
# - Kubernetes service accounts
# - OpenTelemetry Collector deployment
# - Graylog, Elasticsearch, MongoDB deployments
# - Ingress 配置
# - Workload Identity 綁定
