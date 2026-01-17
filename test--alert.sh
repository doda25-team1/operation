#!/bin/bash

# CONFIGURATION
# ------------------------------
# The URL to hit. Adjust the port if using port-forwarding (e.g., 8080)
URL="http://localhost:9081/sms/"

# How fast to send requests? 
# 0.5s sleep = ~120 requests/min (Should trigger a >60 threshold)
# 0.1s sleep = ~600 requests/min
DELAY=0.2 

echo "🔥 Starting Load Generator to trigger Prometheus Alert..."
echo "target: $URL"
echo "delay:  ${DELAY}s per request"
echo "-------------------------------------------------------"

count=0
while true; do
  # Send a request silently (-s), throw away output (-o /dev/null), print HTTP code (-w)
  status=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
  
  if [ "$status" == "000" ]; then
    echo "Error: Could not connect to $URL. Is port-forwarding running?"
    exit 1
  fi

  ((count++))
  echo -ne "Requests sent: $count | Last Status: $status \r"
  
  sleep $DELAY
done