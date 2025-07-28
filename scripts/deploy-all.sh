#!/bin/bash
# 完整部署腳本 - 部署所有服務
# 包含：OpenTelemetry Collector、Java 應用程式、Graylog 系統

set -e

# 設定變數
PROJECT_ID="cloud-sre-poc-465509"
REGION="asia-east1"
CLUSTER_NAME="tracing-gke-cluster"

echo "=== 開始完整部署 ==="

# 1. 取得 GKE 認證
echo "1. 取得 GKE 認證..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

# 2. 執行 Terraform 建立基礎設施
echo "2. 執行 Terraform 建立基礎設施..."
cd ../terraform
terraform init
terraform plan
terraform apply -auto-approve

# 取得 Graylog 外部 IP
GRAYLOG_IP=$(terraform output -raw graylog_external_ip)
echo "Graylog 外部 IP: $GRAYLOG_IP"

cd ../

# 3. 部署 OpenTelemetry Collector
echo "3. 部署 OpenTelemetry Collector..."
kubectl apply -f k8s/opentelemetry/namespace.yaml
kubectl apply -f k8s/opentelemetry/config.yaml
kubectl apply -f k8s/opentelemetry/cluster-role.yaml

# 建立服務帳戶並設定 Workload Identity
kubectl create serviceaccount otel-collector -n opentelemetry --dry-run=client -o yaml | kubectl apply -f -

gcloud iam service-accounts add-iam-policy-binding otel-collector@$PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:$PROJECT_ID.svc.id.goog[opentelemetry/otel-collector]" || true

kubectl annotate serviceaccount otel-collector \
  --namespace opentelemetry \
  iam.gke.io/gcp-service-account=otel-collector@$PROJECT_ID.iam.gserviceaccount.com --overwrite

kubectl apply -f k8s/opentelemetry/collector-daemonset.yaml

# 等待 OpenTelemetry Collector 啟動
echo "等待 OpenTelemetry Collector 啟動..."
kubectl wait --for=condition=ready pod -l app=otel-collector -n opentelemetry --timeout=300s

# 4. 部署 Java 應用程式
echo "4. 部署 Java 應用程式..."
export APP_NAME="app3"
export IMAGE_NAME="asia-east1-docker.pkg.dev/cloud-sre-poc-465509/app-image-repo/tracing-test:ori"
envsubst < k8s/java-apps/app-javaagent-deployment.yaml | kubectl apply -f -

export APP_NAME="app4"
export IMAGE_NAME="asia-east1-docker.pkg.dev/cloud-sre-poc-465509/app-image-repo/tracing-test:ori"
envsubst < k8s/java-apps/app-javaagent-deployment.yaml | kubectl apply -f -

# 5. 部署 Graylog 系統
echo "5. 部署 Graylog 系統..."
kubectl apply -f k8s/graylog/namespace.yaml

# 部署 MongoDB
kubectl apply -f k8s/graylog/mongodb-deployment.yaml
echo "等待 MongoDB 啟動..."
kubectl wait --for=condition=ready pod -l app=mongodb -n graylog --timeout=300s

# 部署 Elasticsearch
kubectl apply -f k8s/graylog/elasticsearch-deployment.yaml
echo "等待 Elasticsearch 啟動..."
kubectl wait --for=condition=ready pod -l app=elasticsearch -n graylog --timeout=300s

# 更新 Graylog 部署檔案中的外部 IP
sed "s/GRAYLOG_EXTERNAL_IP/$GRAYLOG_IP/g" k8s/graylog/graylog-deployment.yaml > /tmp/graylog-deployment-updated.yaml

# 部署 Graylog
kubectl apply -f /tmp/graylog-deployment-updated.yaml

echo "等待 Graylog 啟動..."
kubectl wait --for=condition=ready pod -l app=graylog -n graylog --timeout=600s

# 6. 部署 Ingress（可選）
echo "6. 部署 Graylog Ingress..."
kubectl apply -f k8s/graylog/graylog-ingress.yaml

echo ""
echo "=== 部署完成！ ==="
echo ""
echo "服務狀態檢查："
echo "kubectl get pods --all-namespaces"
echo ""
echo "Graylog Web UI 存取："
echo "URL: http://$GRAYLOG_IP:9000"
echo "帳號: admin"
echo "密碼: admin"
echo ""
echo "OpenTelemetry Collector 狀態："
echo "kubectl get pods -n opentelemetry"
echo ""
echo "Java 應用程式狀態："
echo "kubectl get pods -l app=app3"
echo "kubectl get pods -l app=app4"
echo ""
echo "Graylog 系統狀態："
echo "kubectl get pods -n graylog"
