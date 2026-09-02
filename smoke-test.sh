#!/bin/bash


# Define base URL and target endpoints
BASE_URL="http://localhost:4000"
ENDPOINTS=("" "/health" "/get-example-case")
EXPECTED_STATUS=200
FAILED=0

echo "Starting smoke tests for $BASE_URL..."
echo "-----------------------------------"

# Loop through each endpoint
for ENDPOINT in "${ENDPOINTS[@]}"; do
    TARGET_URL="${BASE_URL}${ENDPOINT}"
    
    echo "Testing: $TARGET_URL"
    
    # Execute curl request with a 10-second timeout
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$TARGET_URL")
    
    echo "Result: HTTP Status $HTTP_STATUS"
    
    # Evaluate the status code
    if [ "$HTTP_STATUS" -ne "$EXPECTED_STATUS" ]; then
        echo "❌ FAILURE: $ENDPOINT returned $HTTP_STATUS (Expected $EXPECTED_STATUS)"
        FAILED=1
    else
        echo "✅ SUCCESS: $ENDPOINT is healthy."
    fi
    echo "-----------------------------------"
done

# Evaluate overall test suite outcome
if [ "$FAILED" -eq 1 ]; then
    echo "SMOKE TEST OVERALL STATUS: FAILED"
    exit 1
else
    echo "SMOKE TEST OVERALL STATUS: PASSED"
    exit 0
fi