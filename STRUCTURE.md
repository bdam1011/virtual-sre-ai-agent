# IaC 目錄結構

```
iac/
├── README.md                           # 專案說明
├── USAGE.md                           # 使用說明
├── STRUCTURE.md                       # 目錄結構說明（本檔案）
├── terraform/                         # Terraform 配置檔案
│   ├── main.tf                       # 主要 Terraform 配置
│   ├── variables.tf                  # 變數定義
│   ├── outputs.tf                    # 輸出值定義
│   └── graylog.tf                    # Graylog 相關資源
├── k8s/                              # Kubernetes YAML 檔案
│   ├── opentelemetry/                # OpenTelemetry Collector
│   │   ├── namespace.yaml           # OpenTelemetry 命名空間
│   │   ├── config.yaml              # Collector 配置
│   │   ├── cluster-role.yaml        # RBAC 權限設定
│   │   └── collector-daemonset.yaml # Collector DaemonSet
│   ├── java-apps/                   # Java 應用程式
│   │   └── app-javaagent-deployment.yaml # Java 應用程式部署模板
│   └── graylog/                     # Graylog 系統 
│       ├── README.md                # Graylog 部署說明和故障排除
│       ├── namespace.yaml           # Graylog 命名空間
│       ├── mongodb-deployment.yaml  # MongoDB 6.0.13 部署
│       ├── elasticsearch-deployment.yaml # Elasticsearch 7.17.18 部署
│       └── graylog-deployment.yaml  # Graylog 6.3.1 主服務部署 (LoadBalancer)
└── scripts/                         # 部署腳本
    ├── deploy-all.sh                # 完整部署腳本
    ├── deploy-apps.sh               # 僅部署 Java 應用程式
    ├── deploy-graylog.sh            # 僅部署 Graylog 系統
    └── cleanup.sh                   # 清理腳本
```

## 檔案說明

### Terraform 檔案
- **main.tf**: 包含 provider 設定、GKE 叢集資料來源、靜態 IP 和防火牆規則
- **variables.tf**: 定義所有可配置的變數，包含專案 ID、區域等
- **outputs.tf**: 定義輸出值，如 Graylog 外部 IP 和存取 URL
- **graylog.tf**: Graylog 相關的 Kubernetes 資源和 GCP 服務帳戶設定

### Kubernetes 檔案
- **opentelemetry/**: OpenTelemetry Collector 相關配置，包含 DaemonSet 部署和 RBAC 設定
- **java-apps/**: Java 應用程式部署模板，支援環境變數替換
- **graylog/**: 完整的 Graylog 堆疊，包含 MongoDB、Elasticsearch 和 Graylog 主服務

### 部署腳本
- **deploy-all.sh**: 完整部署流程，包含所有服務
- **deploy-apps.sh**: 僅部署 Java 應用程式
- **deploy-graylog.sh**: 僅部署 Graylog 系統
- **cleanup.sh**: 清理所有部署的資源

## 使用流程

1. **準備階段**: 確認 GKE 叢集已建立，服務帳戶金鑰已配置
2. **完整部署**: 執行 `./scripts/deploy-all.sh`
3. **驗證部署**: 檢查 Pod 狀態和服務可用性
4. **設定 Graylog**: 登入 Web UI 並配置輸入
5. **測試追蹤**: 測試應用程式間的呼叫和日誌收集
6. **清理資源**: 執行 `./scripts/cleanup.sh`
