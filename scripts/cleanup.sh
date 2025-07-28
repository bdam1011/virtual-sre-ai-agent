#!/bin/bash
# 清理腳本 - 刪除所有部署的資源

set -e

# 設定變數
PROJECT_ID="cloud-sre-poc-465509"
REGION="asia-east1"
CLUSTER_NAME="tracing-gke-cluster"

echo "=== 開始清理所有資源 ==="

# 取得 GKE 認證
echo "取得 GKE 認證..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

# 刪除 Java 應用程式
echo "刪除 Java 應用程式..."
kubectl delete deployment app3 --ignore-not-found=true
kubectl delete deployment app4 --ignore-not-found=true
kubectl delete service app3-service --ignore-not-found=true
kubectl delete service app4-service --ignore-not-found=true

# 刪除 Graylog 系統
echo "刪除 Graylog 系統..."
kubectl delete namespace graylog --ignore-not-found=true

# 刪除 OpenTelemetry Collector
echo "刪除 OpenTelemetry Collector..."
kubectl delete namespace opentelemetry --ignore-not-found=true

# 刪除 ClusterRole 和 ClusterRoleBinding
kubectl delete clusterrole otel-collector --ignore-not-found=true
kubectl delete clusterrolebinding otel-collector --ignore-not-found=true

# 執行 Terraform destroy
echo "執行 Terraform destroy..."
cd ../terraform
terraform destroy -auto-approve

echo ""
echo "=== 清理完成！ ==="
echo ""
echo "檢查剩餘資源："
echo "kubectl get pods --all-namespaces"
echo "kubectl get svc --all-namespaces"
