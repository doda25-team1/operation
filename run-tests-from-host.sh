#!/bin/bash
# Wrapper script to run Istio tests from your host machine
# This script SSHs into the ctrl VM and runs the tests there

# Before running the test ensure VMs are up and running
# cd operation
# vagrant up
# ansible-playbook -i inventory_portforward.ini playbooks/finalization.yml

set -e

echo "🚀 Running Istio Traffic Routing Tests..."
echo ""

# Use the simple test script by default (no buffering issues)
TEST_SCRIPT="${1:-test-istio-simple.sh}"

if [ ! -f "$TEST_SCRIPT" ]; then
    echo "Error: Test script $TEST_SCRIPT not found"
    echo "Available: test-istio-simple.sh (recommended), test-istio-routing-enhanced.sh"
    exit 1
fi

echo "Using test script: $TEST_SCRIPT"
echo ""

# Copy test script to VM
cat "$TEST_SCRIPT" | vagrant ssh ctrl -c "cat > /tmp/test-istio.sh && chmod +x /tmp/test-istio.sh"

# Run the test script in the VM
vagrant ssh ctrl -c "export KUBECONFIG=/etc/kubernetes/admin.conf && sudo -E /tmp/test-istio.sh"

echo ""
echo "✅ Tests completed!"
