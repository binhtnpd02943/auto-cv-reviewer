#!/bin/bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

APP_PORT=3000
MAX_RETRIES=6
RETRY_INTERVAL=10

echo "Checking health of application on port $APP_PORT..."

echo "=========================================================="
echo "🚨 CỐ Ý GÂY LỖI HEALTHCHECK ĐỂ TEST TIẾN TRÌNH ROLLBACK 🚨"
echo "=========================================================="
exit 1

for i in $(seq 1 $MAX_RETRIES); do
    # Assuming there's a basic health route, or just checking if port accepts connections
    # For a proper express app, typically you have a GET / ping or /health
    # We will use curl to test if the port responds to HTTP requests at root or /
    if curl -s -f http://localhost:$APP_PORT/ > /dev/null || curl -s -o /dev/null -w "%{http_code}" http://localhost:$APP_PORT/ | grep -q "200\|404\|401\|403"; then
        echo "Healthcheck passed! Service is responding on port $APP_PORT."
        exit 0
    fi
    
    echo "Attempt $i/$MAX_RETRIES failed. Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
done

echo "Healthcheck failed after $MAX_RETRIES attempts. Consider triggering a rollback."
exit 1
