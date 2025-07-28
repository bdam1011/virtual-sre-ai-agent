# Infrastructure as Code (IaC) 目錄

此目錄包含完整的 Kubernetes 服務部署配置，整合了：

## 服務架構
1. **Java Agent 應用程式** (app3, app4)
2. **OpenTelemetry Collector** (DaemonSet)
3. **Graylog 日誌管理系統** ✅
   - Graylog 6.3.1
   - Elasticsearch 7.17.18
   - MongoDB 6.0.13
   - LoadBalancer 外部存取

## 目錄結構
```
iac/
├── terraform/              # Terraform 配置
│   ├── main.tf             # 主要配置
│   ├── variables.tf        # 變數定義
│   ├── graylog.tf          # Graylog 相關資源
│   └── outputs.tf          # 輸出值
├── k8s/                    # Kubernetes YAML 檔案
│   ├── java-apps/          # Java 應用程式
│   ├── opentelemetry/      # OpenTelemetry Collector
│   └── graylog/            # Graylog 相關服務
└── scripts/                # 部署腳本
    ├── deploy-all.sh       # 完整部署腳本
    ├── deploy-apps.sh      # 僅部署應用程式
    └── deploy-graylog.sh   # 僅部署 Graylog
```

## 部署順序
1. 執行 Terraform 建立基礎設施
2. 部署 OpenTelemetry Collector
3. 部署 Java 應用程式
4. 部署 Graylog 系統

## 使用方式
```bash
# 完整部署
./scripts/deploy-all.sh

# 或分別部署
./scripts/deploy-apps.sh
./scripts/deploy-graylog.sh
```
