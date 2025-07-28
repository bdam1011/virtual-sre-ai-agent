#!/bin/bash
# 部署 Java 應用程式腳本
# 僅部署 app3 和 app4 應用程式

set -e

# 設定變數
PROJECT_ID="cloud-sre-poc-465509"
REGION="asia-east1"
CLUSTER_NAME="tracing-gke-cluster"

echo "=== 開始部署 Java 應用程式 ==="

# 取得 GKE 認證
echo "取得 GKE 認證..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

# 確認 OpenTelemetry Collector 已部署
if ! kubectl get namespace opentelemetry &> /dev/null; then
    echo "錯誤：OpenTelemetry namespace 不存在，請先執行 deploy-all.sh"
    exit 1
fi

if ! kubectl get pods -n opentelemetry -l app=otel-collector | grep -q Running; then
    echo "警告：OpenTelemetry Collector 可能未正常運行"
fi

# 部署 app3
echo "部署 app3..."
export APP_NAME="app3"
export IMAGE_NAME="asia-east1-docker.pkg.dev/cloud-sre-poc-465509/app-image-repo/tracing-test:ori"
envsubst < ../k8s/java-apps/app-javaagent-deployment.yaml | kubectl apply -f -
kubectl rollout restart deployment app3 || true

# 部署 app4
echo "部署 app4..."
export APP_NAME="app4"
export IMAGE_NAME="asia-east1-docker.pkg.dev/cloud-sre-poc-465509/app-image-repo/tracing-test:ori"
envsubst < ../k8s/java-apps/app-javaagent-deployment.yaml | kubectl apply -f -
kubectl rollout restart deployment app4 || true

echo ""
echo "=== Java 應用程式部署完成！ ==="
echo ""
echo "檢查部署狀態："
echo "kubectl get pods -l app=app3"
echo "kubectl get pods -l app=app4"
echo "kubectl get svc -l app=app3"
echo "kubectl get svc -l app=app4"
