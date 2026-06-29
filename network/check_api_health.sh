#!/usr/bin/env bash
#
# Hit an endpoint and emit curl timing metrics as JSON.
#
# Usage: ./check_api_health.sh <URL> [timeout]

set -euo pipefail

TARGET_URL="${1:-}"
TIMEOUT="${2:-10}"

if [[ -z "$TARGET_URL" ]]; then
    echo "Usage: $0 <URL> [timeout_in_seconds]" >&2
    exit 1
fi

curl -sS -L -o /dev/null -m "$TIMEOUT" -w '{
  "http_code": "%{http_code}",
  "time_total": %{time_total},
  "time_namelookup": %{time_namelookup},
  "time_connect": %{time_connect},
  "time_appconnect": %{time_appconnect},
  "time_starttransfer": %{time_starttransfer},
  "size_download": %{size_download}
}
' "$TARGET_URL"
