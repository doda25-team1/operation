#!/bin/bash
# Test case for sms-app with Istio + Rate Limit (x-user-id header)

# ================================
# CONFIGURATION
# ================================
GATEWAY_HOST="localhost"
GATEWAY_PORT=8087
APP_PATH="/sms/"
MAX_REQUESTS=10  # Per-user limit in config
USERS=("user1" "user2")  # List of test users

# ================================
# FUNCTION: SEND REQUESTS
# ================================
send_requests() {
    local user=$1
    echo "===== Testing user: $user ====="
    for i in $(seq 1 $((MAX_REQUESTS+2))); do
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "x-user-id: $user" http://$GATEWAY_HOST:$GATEWAY_PORT$APP_PATH)
        echo "Request $i: HTTP $RESPONSE"
    done
    echo ""
}

# ================================
# TEST ALL USERS
# ================================
for user in "${USERS[@]}"; do
    send_requests $user
done
