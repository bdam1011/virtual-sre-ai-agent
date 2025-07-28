#!/bin/bash
# 部署 Graylog 系統腳本
# 包含 MongoDB、Elasticsearch 和 Graylog

set -e

# 設定變數
PROJECT_ID="cloud-sre-poc-465509"
REGION="asia-east1"
CLUSTER_NAME="tracing-gke-cluster"

echo "=== 開始部署 Graylog 系統 ==="

# 取得 GKE 認證
echo "取得 GKE 認證..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

# 確認 Terraform 已執行並取得 Graylog IP
cd ../terraform
if [ ! -f "terraform.tfstate" ]; then
    echo "執行 Terraform 建立基礎設施..."
    terraform init
    terraform apply -auto-approve
fi

GRAYLOG_IP=$(terraform output -raw graylog_external_ip)
echo "Graylog 外部 IP: $GRAYLOG_IP"
cd ../

# 建立 Graylog namespace
echo "建立 Graylog namespace..."
kubectl apply -f k8s/graylog/namespace.yaml

# 部署 MongoDB
echo "部署 MongoDB..."
kubectl apply -f k8s/graylog/mongodb-deployment.yaml
echo "等待 MongoDB 啟動..."
kubectl wait --for=condition=ready pod -l app=mongodb -n graylog --timeout=300s

# 部署 Elasticsearch
echo "部署 Elasticsearch..."
kubectl apply -f k8s/graylog/elasticsearch-deployment.yaml
echo "等待 Elasticsearch 啟動..."
kubectl wait --for=condition=ready pod -l app=elasticsearch -n graylog --timeout=300s

# 更新 Graylog 部署檔案中的外部 IP
echo "更新 Graylog 配置..."
sed "s/GRAYLOG_EXTERNAL_IP/$GRAYLOG_IP/g" k8s/graylog/graylog-deployment.yaml > /tmp/graylog-deployment-updated.yaml

# BackendConfig 不再需要（使用 LoadBalancer 而非 Ingress）
echo "跳過 BackendConfig 部署（使用 LoadBalancer）..."

# 部署 Graylog
echo "部署 Graylog..."
kubectl apply -f /tmp/graylog-deployment-updated.yaml
echo "等待 Graylog 啟動..."
kubectl wait --for=condition=ready pod -l app=graylog -n graylog --timeout=600s

# LoadBalancer 部署完成，無需部署 Ingress
echo "LoadBalancer 部署完成，等待外部 IP 配置..."

echo ""
echo "=== Graylog 系統部署完成！ ==="
echo ""
echo "Graylog Web UI 存取："
echo "URL: http://$GRAYLOG_IP:9000"
echo "帳號: admin"
echo "密碼: admin"
echo ""
echo "注意：LoadBalancer 可能需要幾分鐘時間才能完全就緒"
echo ""
echo "檢查部署狀態："
echo "kubectl get pods -n graylog"
echo "kubectl get svc -n graylog"
echo "kubectl get ingress -n graylog"
echo ""
echo "設定 Graylog 輸入："
echo "1. 登入 Graylog Web UI"
echo "2. 進入 System → Inputs"
echo "3. 選擇 'GELF UDP' 輸入"
echo "4. 設定 Port: 12201"
echo "5. 儲存設定"
