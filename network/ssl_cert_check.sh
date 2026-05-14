#!/usr/bin/env bash
#
# ssl_cert_check.sh
# 
# Purpose: Diagnostic tool to quickly verify the validity and expiration
# date of an SSL/TLS certificate for a given domain.
# Useful for ruling out expired certs during sudden outage escalations.
#
# Usage: ./ssl_cert_check.sh <DOMAIN> [PORT]
# Example: ./ssl_cert_check.sh example.com 443

set -euo pipefail

DOMAIN="${1:-}"
PORT="${2:-443}"

if [[ -z "$DOMAIN" ]]; then
    echo "Error: Domain is required."
    echo "Usage: $0 <DOMAIN> [PORT]"
    exit 1
fi

echo "Checking SSL Certificate for: ${DOMAIN}:${PORT}"
echo "------------------------------------------------"

# Use openssl s_client to fetch the certificate details
# We pipe to openssl x509 to extract human-readable text
CERT_INFO=$(echo | openssl s_client -servername "$DOMAIN" -connect "${DOMAIN}:${PORT}" 2>/dev/null | openssl x509 -noout -text 2>/dev/null || true)

if [[ -z "$CERT_INFO" ]]; then
    echo "Failed to retrieve certificate. The connection may have timed out, or the domain is not serving SSL on port ${PORT}."
    exit 2
fi

# Extract relevant fields
ISSUER=$(echo "$CERT_INFO" | grep -i "Issuer:" | sed -e 's/^[ \t]*//')
SUBJECT=$(echo "$CERT_INFO" | grep -i "Subject:" | grep -v "Subject Public Key" | sed -e 's/^[ \t]*//')
NOT_BEFORE=$(echo "$CERT_INFO" | grep "Not Before:" | sed -e 's/^[ \t]*//' | cut -d: -f2- | awk '{$1=$1};1')
NOT_AFTER=$(echo "$CERT_INFO" | grep "Not After :" | sed -e 's/^[ \t]*//' | cut -d: -f2- | awk '{$1=$1};1')

echo "$SUBJECT"
echo "$ISSUER"
echo "Valid From: $NOT_BEFORE"
echo "Valid To:   $NOT_AFTER"
echo "------------------------------------------------"

# Calculate days remaining (macOS and Linux date command syntax differ slightly)
# This uses a generic approach that works broadly or falls back gracefully
if command -v date >/dev/null 2>&1; then
    # Try GNU date format first (Linux)
    EXPIRATION_EPOCH=$(date -d "$NOT_AFTER" +%s 2>/dev/null || true)
    
    # If that failed, try BSD date format (macOS)
    if [[ -z "$EXPIRATION_EPOCH" ]]; then
        EXPIRATION_EPOCH=$(date -j -f "%b %d %T %Y %Z" "$NOT_AFTER" +%s 2>/dev/null || true)
    fi

    if [[ -n "$EXPIRATION_EPOCH" ]]; then
        CURRENT_EPOCH=$(date +%s)
        SECONDS_REMAINING=$((EXPIRATION_EPOCH - CURRENT_EPOCH))
        DAYS_REMAINING=$((SECONDS_REMAINING / 86400))
        
        if [[ $DAYS_REMAINING -lt 0 ]]; then
             echo -e "\033[0;31m[CRITICAL] Certificate EXPIRED ${DAYS_REMAINING#-} days ago.\033[0m"
        elif [[ $DAYS_REMAINING -lt 14 ]]; then
             echo -e "\033[0;33m[WARNING] Certificate expires soon: $DAYS_REMAINING days remaining.\033[0m"
        else
             echo -e "\033[0;32m[OK] Certificate is valid. $DAYS_REMAINING days remaining.\033[0m"
        fi
    else
        echo "Note: Could not calculate remaining days automatically on this OS."
    fi
fi

exit 0
