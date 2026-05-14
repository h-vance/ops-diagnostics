#!/usr/bin/env bash
#
# check_api_health.sh
# 
# Purpose: Basic API health checking script for rapid diagnostic triage.
# This script hits a target endpoint, extracts the HTTP status code, total response
# time, and response size, without modifying or saving the payload.
# Useful for quickly isolating "is the service down or is it just slow" scenarios.
#
# Usage: ./check_api_health.sh <URL> [timeout]
# Example: ./check_api_health.sh https://api.example.com/v1/health 5

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration & Argument Parsing
# ---------------------------------------------------------------------------
TARGET_URL="${1:-}"
TIMEOUT="${2:-10}"

if [[ -z "$TARGET_URL" ]]; then
    echo "Error: Target URL is required."
    echo "Usage: $0 <URL> [timeout_in_seconds]"
    exit 1
fi

# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------
echo "Target:  $TARGET_URL"
echo "Timeout: ${TIMEOUT}s"
echo "--------------------------------------------------------"

# Curl format string for structured output
FORMAT_STRING='{
  "http_code": "%{http_code}",
  "time_total": %{time_total},
  "time_namelookup": %{time_namelookup},
  "time_connect": %{time_connect},
  "time_appconnect": %{time_appconnect},
  "time_starttransfer": %{time_starttransfer},
  "size_download": %{size_download}
}'

# Execute curl, suppressing progress meter, following redirects (-L), and 
# outputting only our custom format string. The actual response body is 
# discarded to /dev/null.
RESULT=$(curl -s -L -w "$FORMAT_STRING" -o /dev/null -m "$TIMEOUT" "$TARGET_URL" || true)

# ---------------------------------------------------------------------------
# Output Processing
# ---------------------------------------------------------------------------
if [[ -z "$RESULT" ]]; then
    echo "Result:  CONNECTION FAILED (Timeout or DNS error)"
    exit 2
fi

# Basic parsing utilizing jq if available, otherwise raw output
if command -v jq >/dev/null 2>&1; then
    HTTP_CODE=$(echo "$RESULT" | jq -r '.http_code')
    TIME_TOTAL=$(echo "$RESULT" | jq -r '.time_total')
    
    if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" || "$HTTP_CODE" == "202" || "$HTTP_CODE" == "204" ]]; then
        STATUS="SUCCESS"
        COLOR="\033[0;32m" # Green
    elif [[ "$HTTP_CODE" == "000" ]]; then
        STATUS="CONNECTION FAILED"
        COLOR="\033[0;31m" # Red
    else
        STATUS="ERROR"
        COLOR="\033[0;31m" # Red
    fi
    NC="\033[0m" # No Color

    echo -e "Status:  ${COLOR}${STATUS} (HTTP ${HTTP_CODE})${NC}"
    echo "Latency: ${TIME_TOTAL}s"
    
    # Optional: print detailed breakdown
    echo ""
    echo "Detailed Breakdown (JSON):"
    echo "$RESULT" | jq .
else
    # Fallback if jq is not installed
    echo "Status: HTTP code was extracted, but jq is missing for pretty printing."
    echo "Raw Metrics:"
    echo "$RESULT"
fi

exit 0
