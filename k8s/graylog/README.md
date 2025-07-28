# Graylog on GKE 部署指南

## 概述

本項目在 Google Kubernetes Engine (GKE) 上部署 Graylog 日誌管理系統，使用 LoadBalancer Service 進行外部存取。

## 架構

- **Graylog 6.3.1**: 主要的日誌管理系統
- **Elasticsearch 8.11.4**: 日誌存儲後端
- **MongoDB 6.0.13**: 配置和元數據存儲
- **LoadBalancer**: 提供外部存取 (port 9000)
- **GELF Service**: 處理日誌輸入 (port 12201 TCP/UDP)

## 部署前準備

1. 確保 Terraform 已建立 GKE 集群和 Static IP
2. 確保有 GCP 和 kubectl 的存取權限

## 部署步驟

### 1. 建立基礎設施
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

### 2. 部署 Graylog 系統
```bash
cd ../scripts
./deploy-graylog.sh
```

### 3. 驗證部署
```bash
kubectl get pods -n graylog
kubectl get svc -n graylog
```

## 存取方式

- **Web UI**: `http://[STATIC_IP]:9000`
- **預設帳號**: `admin`
- **預設密碼**: `admin`

## 服務說明

### graylog-service (LoadBalancer)
- **用途**: Graylog Web UI 存取
- **端口**: 9000
- **類型**: LoadBalancer
- **外部 IP**: 由 Terraform 建立的 Static IP

### graylog-gelf-service (ClusterIP)
- **用途**: GELF 日誌輸入
- **端口**: 12201 (TCP/UDP)
- **類型**: ClusterIP (僅供集群內部使用)

## 故障排除

### 常見問題

1. **Graylog 6.3.1 CrashLoopBackOff**
   - **問題**: 容器權限問題，無法寫入 `/usr/share/graylog/data/journal`
   - **解決方案**: 添加 `securityContext` 和 `initContainer` 設定正確權限
   - **配置**: `runAsUser: 1100`, `fsGroup: 1100`

2. **Elasticsearch 版本相容性錯誤**
   - **問題**: `Invalid Search version specified in elasticsearch_version: Elasticsearch:8.0.0`
   - **原因**: Graylog 6.3.1 不支援 Elasticsearch 8.x
   - **解決方案**: 降級到 Elasticsearch 7.17.18

3. **LoadBalancer 無法取得外部 IP**
   - 確認 GCP 防火牆規則
   - 檢查 VPC 網路設定
   - 驗證 Static IP 資源是否存在
   - **注意**: GCP LoadBalancer 不支援同一 Service 混用 TCP/UDP狀態

### LoadBalancer 無法取得外部 IP
- 檢查 Static IP 是否正確建立
- 確認沒有 Mixed Protocol (TCP+UDP) 在同一個 LoadBalancer Service

### 外部無法存取
- 檢查 GCP 防火牆規則
- 確認 LoadBalancer Service 狀態

### 查看日誌
```bash
kubectl logs -n graylog deployment/graylog
kubectl describe svc graylog-service -n graylog
```

## 版本相容性

### 版本信息

- **Graylog**: 6.3.1 
- **Elasticsearch**: 7.17.18 
- **MongoDB**: 6.0.13 

### 升級注意事項
1. **Elasticsearch 版本限制**: Graylog 6.3.1 僅支援 Elasticsearch 7.x 或 OpenSearch 1.x/2.x，不支援 Elasticsearch 8.x
2. **MongoDB 6.x**: 向後相容，保持現有配置
3. **記憶體配置**: Graylog JVM heap 增加到 2GB
4. **安全配置**: Elasticsearch 7.17.18 已禁用 X-Pack 安全功能以簡化配置包含最新的安全修復和功能改進

## 重要注意事項

1. **不要使用 Ingress**: 此配置使用 LoadBalancer，避免與 Ingress 衝突
2. **Mixed Protocol 分離**: TCP 和 UDP 服務已分離到不同的 Service
3. **Static IP**: 使用區域性 Static IP，與 GKE 集群在同一區域
4. **安全性**: 生產環境請修改預設密碼
5. **版本升級**: 升級前請備份數據，特別是 MongoDB 和 Elasticsearch 數據

## 配置文件說明

- `namespace.yaml`: 建立 graylog namespace
- `mongodb-deployment.yaml`: MongoDB 部署和服務
- `elasticsearch-deployment.yaml`: Elasticsearch 部署和服務
- `graylog-deployment.yaml`: Graylog 部署和兩個服務 (LoadBalancer + GELF)
