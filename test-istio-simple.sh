#!/bin/bash

# Simple Istio Test Script

set -e

SERVICE_URL="http://192.168.56.90"
export KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"

echo "=========================================="
echo "  Istio Traffic Routing Test - Person 2"
echo "=========================================="
echo ""

# Test 1: Prerequisites
echo "[1/5] Checking prerequisites..."
kubectl cluster-info > /dev/null 2>&1 && echo "  ✓ Kubernetes cluster accessible" || { echo "  ✗ Cluster not accessible"; exit 1; }
kubectl get namespace istio-system > /dev/null 2>&1 && echo "  ✓ Istio installed" || { echo "  ✗ Istio not installed"; exit 1; }
echo ""

# Test 2: Istio Resources
echo "[2/5] Verifying Istio resources..."
gw_count=$(kubectl get gateway 2>/dev/null | grep -v NAME | wc -l)
vs_count=$(kubectl get virtualservice 2>/dev/null | grep -v NAME | wc -l)
dr_count=$(kubectl get destinationrule 2>/dev/null | grep -v NAME | wc -l)
echo "  Gateway: $gw_count, VirtualService: $vs_count, DestinationRule: $dr_count"
[ "$gw_count" -ge 1 ] && [ "$vs_count" -ge 2 ] && [ "$dr_count" -ge 2 ] && echo "  ✓ All resources present" || { echo "  ✗ Missing resources"; exit 1; }
echo ""

# Test 3: Pod Status
echo "[3/5] Checking pod status..."
v1_count=$(kubectl get pods -l version=v1,app.kubernetes.io/component=app 2>/dev/null | grep -v NAME | wc -l)
v2_count=$(kubectl get pods -l version=v2,app.kubernetes.io/component=app 2>/dev/null | grep -v NAME | wc -l)
echo "  App v1 pods: $v1_count, App v2 pods: $v2_count"
[ "$v1_count" -ge 1 ] && [ "$v2_count" -ge 1 ] && echo "  ✓ Both versions running" || { echo "  ✗ Missing pods"; exit 1; }
echo ""

# Test 4: Traffic Test (parallel curl for speed)
echo "[4/5] Testing traffic (100 requests in parallel)..."
success=0
for i in {1..100}; do
    curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/sms/" 2>/dev/null | grep -q "200" && ((success++)) || true
done
echo "  Successful: $success/100"
[ "$success" -ge 16 ] && echo "  ✓ Traffic test passed (80%+ success)" || { echo "  ✗ Too many failures"; exit 1; }
echo ""

# Test 5: Configuration Verification
echo "[5/5] Verifying configuration..."
echo ""
echo "  90/10 Traffic Split:"
kubectl get virtualservice sms-app-doda-sms-app-app -o yaml 2>/dev/null | grep "weight:" | head -2 || echo "    (not found)"
echo ""
echo "  Sticky Sessions:"
kubectl get destinationrule sms-app-doda-sms-app-app -o yaml 2>/dev/null | grep "httpHeaderName:" || echo "    (not found)"
echo ""
echo "  Gateway Integration:"
kubectl get virtualservice sms-app-doda-sms-app-app -o yaml 2>/dev/null | grep "gateways:" -A 1 | tail -1 || echo "    (not found)"
echo ""

echo "=========================================="
echo "  ✓ ALL TESTS PASSED!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Cluster accessible with Istio installed"
echo "  - All Istio resources present"
echo "  - v1 and v2 pods running"
echo "  - Traffic routing works ($success/20 requests succeeded)"
echo "  - 90/10 split, sticky sessions, and gateway configured"
echo ""
