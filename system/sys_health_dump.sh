#!/usr/bin/env bash
#
# sys_health_dump.sh
# 
# Purpose: Generate a rapid, point-in-time snapshot of system health.
# This script is designed to be run during an active incident (e.g., high load, 
# unresponsiveness) to capture transient state that might be lost if the machine 
# is rebooted or if the load subsides.
# 
# Usage: ./sys_health_dump.sh
# Output: Writes a timestamped log file to the current directory (or /tmp)

set -euo pipefail

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
HOSTNAME=$(hostname)
OUTFILE="/tmp/sys_health_${HOSTNAME}_${TIMESTAMP}.log"

echo "Capturing system health snapshot to: $OUTFILE"

# Start writing to the log file
{
    echo "=========================================================="
    echo " SYSTEM HEALTH DUMP: $HOSTNAME @ $(date)"
    echo "=========================================================="
    
    echo -e "\n[1] UPTIME & LOAD AVERAGE"
    uptime

    echo -e "\n[2] MEMORY USAGE"
    if command -v free >/dev/null 2>&1; then
        free -m
    else
        # Fallback for macOS/BSD
        vm_stat
    fi

    echo -e "\n[3] DISK SPACE"
    df -h | grep -v 'tmpfs\|cdrom\|loop'

    echo -e "\n[4] TOP 10 PROCESSES BY CPU"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        top -l 1 -o cpu -n 10
    else
        top -b -n 1 | head -n 17 | tail -n 11
    fi

    echo -e "\n[5] TOP 10 PROCESSES BY MEMORY"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        top -l 1 -o mem -n 10
    else
        ps aux --sort=-%mem | head -n 11
    fi

    echo -e "\n[6] NETWORK CONNECTIONS (ESTABLISHED vs TIME_WAIT)"
    if command -v ss >/dev/null 2>&1; then
        ss -s
    elif command -v netstat >/dev/null 2>&1; then
        netstat -an | grep tcp | awk '{print $6}' | sort | uniq -c
    else
        echo "Neither 'ss' nor 'netstat' is available."
    fi

    echo -e "\n[7] KERNEL MESSAGES (Last 20 lines)"
    if command -v dmesg >/dev/null 2>&1; then
        # dmesg might require root on some modern linux boxes
        dmesg -T | tail -n 20 2>/dev/null || echo "Permission denied reading dmesg without sudo."
    elif [[ -f /var/log/messages ]]; then
        tail -n 20 /var/log/messages 2>/dev/null || echo "Permission denied reading /var/log/messages."
    elif [[ -f /var/log/syslog ]]; then
        tail -n 20 /var/log/syslog 2>/dev/null || echo "Permission denied reading /var/log/syslog."
    fi

    echo "=========================================================="
    echo " DUMP COMPLETE "
    echo "=========================================================="
} > "$OUTFILE"

echo -e "\nSnapshot saved to $OUTFILE"
echo "Please attach this file to the relevant incident ticket."
exit 0
