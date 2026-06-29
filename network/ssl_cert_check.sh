#!/usr/bin/env bash
#
# Verify SSL/TLS certificate dates and warn when expiry is near.
#
# Usage: ./ssl_cert_check.sh <DOMAIN> [PORT]

set -euo pipefail

DOMAIN="${1:-}"
PORT="${2:-443}"
WARNING_SECONDS=1209600

if [[ -z "$DOMAIN" ]]; then
    echo "Usage: $0 <DOMAIN> [PORT]" >&2
    exit 1
fi

echo "Checking SSL Certificate for: ${DOMAIN}:${PORT}"

cert() {
    openssl s_client -servername "$DOMAIN" -connect "${DOMAIN}:${PORT}" </dev/null 2>/dev/null
}

if ! cert | openssl x509 -noout -subject -issuer -dates; then
    echo "Failed to retrieve certificate. The connection may have timed out, or the domain is not serving SSL on port ${PORT}."
    exit 2
fi

if ! cert | openssl x509 -noout -checkend 0 >/dev/null; then
    echo -e "\033[0;31m[CRITICAL] Certificate is expired.\033[0m"
elif ! cert | openssl x509 -noout -checkend "$WARNING_SECONDS" >/dev/null; then
    echo -e "\033[0;33m[WARNING] Certificate expires within 14 days.\033[0m"
else
    echo -e "\033[0;32m[OK] Certificate is valid for at least 14 days.\033[0m"
fi
