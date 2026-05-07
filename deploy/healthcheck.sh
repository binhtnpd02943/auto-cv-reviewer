#!/bin/bash
set -Eeuo pipefail

ENV=$1
PORT=$([ "$ENV" == "production" ] && echo 3000 || echo 3001)
URL="http://localhost:$PORT/"
MAX_RETRIES=6
RETRY_DELAY=5

echo "Healthcheck: Waiting for container to initialize..."
sleep 5

echo "Healthcheck: Pinging $URL for $ENV environment..."

for ((i=1;i<=MAX_RETRIES;i++)); do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || echo "000")
    
    if [ "$HTTP_STATUS" == "200" ]; then
        echo "✅ Healthcheck passed! Service is responding with 200 OK."
        exit 0
    else
        echo "⚠️ Attempt $i/$MAX_RETRIES: Received HTTP $HTTP_STATUS. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
    fi
done

echo "❌ Healthcheck failed! Service did not respond with 200 OK after $(($MAX_RETRIES * $RETRY_DELAY)) seconds."
exit 1
