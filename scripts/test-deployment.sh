#!/bin/bash
# 部署驗證測試腳本
# 檢查所有服務是否正常運行並進行基本功能測試

set -e

echo "=== 開始部署驗證測試 ==="

# 1. 檢查 OpenTelemetry Collector 狀態
echo "1. 檢查 OpenTelemetry Collector..."
if kubectl get pods -n opentelemetry -l app=otel-collector | grep -q Running; then
    echo "✓ OpenTelemetry Collector 運行正常"
else
    echo "✗ OpenTelemetry Collector 未正常運行"
    kubectl get pods -n opentelemetry
fi

# 2. 檢查 Java 應用程式狀態
echo "2. 檢查 Java 應用程式..."
if kubectl get pods -l app=app3 | grep -q Running; then
    echo "✓ app3 運行正常"
else
    echo "✗ app3 未正常運行"
fi

if kubectl get pods -l app=app4 | grep -q Running; then
    echo "✓ app4 運行正常"
else
    echo "✗ app4 未正常運行"
fi

# 3. 檢查 Graylog 系統狀態
echo "3. 檢查 Graylog 系統..."
if kubectl get pods -n graylog -l app=mongodb | grep -q Running; then
    echo "✓ MongoDB 運行正常"
else
    echo "✗ MongoDB 未正常運行"
fi

if kubectl get pods -n graylog -l app=elasticsearch | grep -q Running; then
    echo "✓ Elasticsearch 運行正常"
else
    echo "✗ Elasticsearch 未正常運行"
fi

if kubectl get pods -n graylog -l app=graylog | grep -q Running; then
    echo "✓ Graylog 運行正常"
else
    echo "✗ Graylog 未正常運行"
fi

# 4. 檢查服務連通性
echo "4. 檢查服務連通性..."

# 檢查 app3 健康狀態
APP3_POD=$(kubectl get pods -l app=app3 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ ! -z "$APP3_POD" ]; then
    if kubectl exec $APP3_POD -- curl -s http://localhost:8080/actuator/health/readiness | grep -q UP; then
        echo "✓ app3 健康檢查通過"
    else
        echo "✗ app3 健康檢查失敗"
    fi
fi

# 檢查 app4 健康狀態
APP4_POD=$(kubectl get pods -l app=app4 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ ! -z "$APP4_POD" ]; then
    if kubectl exec $APP4_POD -- curl -s http://localhost:8080/actuator/health/readiness | grep -q UP; then
        echo "✓ app4 健康檢查通過"
    else
        echo "✗ app4 健康檢查失敗"
    fi
fi

# 5. 測試應用程式間呼叫
echo "5. 測試應用程式間呼叫..."
if [ ! -z "$APP3_POD" ] && [ ! -z "$APP4_POD" ]; then
    echo "測試 app3 呼叫 app4..."
    if kubectl exec $APP3_POD -- curl -s "http://127.0.0.1:8080/call-other?podUrl=http://app4-service:8080" | grep -q "success\|ok\|200"; then
        echo "✓ 應用程式間呼叫測試成功"
    else
        echo "✗ 應用程式間呼叫測試失敗"
    fi
fi

# 6. 檢查 Graylog Web UI 可用性
echo "6. 檢查 Graylog Web UI..."
GRAYLOG_IP=$(kubectl get svc -n graylog graylog-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
if [ ! -z "$GRAYLOG_IP" ]; then
    echo "Graylog Web UI: http://$GRAYLOG_IP:9000"
    if curl -s --connect-timeout 10 "http://$GRAYLOG_IP:9000" | grep -q "Graylog\|login"; then
        echo "✓ Graylog Web UI 可存取"
    else
        echo "✗ Graylog Web UI 無法存取"
    fi
else
    echo "! Graylog 外部 IP 尚未分配"
fi

echo ""
echo "=== 驗證測試完成 ==="
echo ""
echo "詳細狀態檢查："
echo "kubectl get pods --all-namespaces"
echo "kubectl get svc --all-namespaces"
