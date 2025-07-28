# IaC 使用說明

## 前置需求

1. **工具安裝**：
   - Terraform >= 1.0.0
   - gcloud CLI（含 GKE plugin）
   - kubectl
   - Docker

2. **GCP 設定**：
   - 確保 GKE 叢集 `tracing-gke-cluster` 已建立
   - 服務帳戶金鑰檔案已放置在正確位置
   - 必要的 API 已啟用

## 快速開始

### 完整部署
```bash
cd iac/scripts
./deploy-all.sh
```

### 分別部署
```bash
# 1. 僅部署 Java 應用程式
./deploy-apps.sh

# 2. 僅部署 Graylog 系統
./deploy-graylog.sh
```

### 清理資源
```bash
./cleanup.sh
```

## 部署後驗證

### 1. 檢查所有 Pod 狀態
```bash
kubectl get pods --all-namespaces
```

### 2. 檢查服務狀態
```bash
kubectl get svc --all-namespaces
```

### 3. 存取 Graylog Web UI ✅
- **版本**: Graylog 6.3.1 + Elasticsearch 7.17.18 + MongoDB 6.0.13
- **URL**: http://104.199.248.173:9000 (LoadBalancer)
- **帳號**: admin
- **密碼**: admin
- **狀態**: 所有服務正常運行

### 4. 測試應用程式追蹤
```bash
# 進入 app3 Pod
kubectl exec -it deployment/app3 -- /bin/sh

# 呼叫 app4
curl 'http://127.0.0.1:8080/call-other?podUrl=http://app4-service:8080'
```

## 服務架構

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Java Apps     │    │  OpenTelemetry   │    │   GCP Services  │
│   (app3, app4)  │───▶│    Collector     │───▶│  Cloud Trace    │
└─────────────────┘    └──────────────────┘    │  Cloud Logging  │
                                │               │  Cloud Monitor  │
                                │               └─────────────────┘
                                ▼
                       ┌─────────────────┐
                       │    Graylog      │
                       │   (MongoDB +    │
                       │ Elasticsearch)  │
                       └─────────────────┘
```

## 設定 Graylog 輸入

1. 登入 Graylog Web UI
2. 進入 **System → Inputs**
3. 選擇 **GELF UDP** 輸入
4. 設定：
   - Title: OpenTelemetry Logs
   - Port: 12201
   - Bind address: 0.0.0.0
5. 點擊 **Save**

## 故障排除

### OpenTelemetry Collector 無法啟動
```bash
kubectl logs -l app=otel-collector -n opentelemetry
```

### Graylog 無法存取
```bash
kubectl logs -l app=graylog -n graylog
kubectl get svc -n graylog
```

### Java 應用程式無法連接 Collector
```bash
kubectl logs deployment/app3
kubectl logs deployment/app4
```

## 自訂設定

### 修改 OpenTelemetry Collector 配置
編輯 `k8s/opentelemetry/config.yaml`

### 修改 Graylog 設定
編輯 `k8s/graylog/graylog-deployment.yaml`

### 修改 Terraform 變數
編輯 `terraform/variables.tf`
