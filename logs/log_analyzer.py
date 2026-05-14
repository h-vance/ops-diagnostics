#!/usr/bin/env python3
"""
log_analyzer.py

Purpose: A robust, zero-dependency Python script to analyze structured (JSON) 
or standard web server logs. It aggregates HTTP status codes, identifies 
high-frequency error endpoints, and profiles top client IPs.

Usage: 
    python3 log_analyzer.py <path_to_logfile> [--format json|nginx]
    
Example:
    python3 log_analyzer.py /var/log/nginx/access.log --format nginx
"""

import sys
import json
import re
import argparse
from collections import Counter
from typing import Dict, List, Tuple

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Diagnostic log analyzer for SaaS support triage.")
    parser.add_argument("logfile", help="Path to the log file to analyze")
    parser.add_argument("--format", choices=["json", "nginx"], default="json",
                        help="Format of the log file (default: json)")
    parser.add_argument("--limit", type=int, default=10,
                        help="Number of top entries to display (default: 10)")
    return parser.parse_args()

def analyze_json_logs(filepath: str, limit: int) -> None:
    """Parses JSON formatted logs, assuming fields like 'status', 'path', 'ip' exist."""
    status_counts = Counter()
    endpoint_errors = Counter()
    ip_counts = Counter()
    total_lines = 0
    parsed_lines = 0

    try:
        with open(filepath, 'r') as f:
            for line in f:
                total_lines += 1
                try:
                    data = json.loads(line.strip())
                    parsed_lines += 1
                    
                    status = str(data.get('status', data.get('statusCode', 'unknown')))
                    path = data.get('path', data.get('url', 'unknown'))
                    ip = data.get('ip', data.get('client_ip', 'unknown'))
                    
                    status_counts[status] += 1
                    ip_counts[ip] += 1
                    
                    if status.startswith('5') or status.startswith('4'):
                         endpoint_errors[f"{status} {path}"] += 1

                except json.JSONDecodeError:
                    continue
    except FileNotFoundError:
        print(f"Error: File '{filepath}' not found.")
        sys.exit(1)

    print_report(total_lines, parsed_lines, status_counts, endpoint_errors, ip_counts, limit)

def analyze_nginx_logs(filepath: str, limit: int) -> None:
    """Parses standard combined Nginx log format."""
    # Standard combined log format regex
    log_pattern = re.compile(
        r'(?P<ip>\S+) \S+ \S+ \[[^\]]+\] "(?P<method>\S+) (?P<path>\S+) \S+" (?P<status>\d{3}) \d+ ".*?" ".*?"'
    )
    
    status_counts = Counter()
    endpoint_errors = Counter()
    ip_counts = Counter()
    total_lines = 0
    parsed_lines = 0

    try:
        with open(filepath, 'r') as f:
            for line in f:
                total_lines += 1
                match = log_pattern.match(line)
                if match:
                    parsed_lines += 1
                    data = match.groupdict()
                    
                    status = data['status']
                    path = data['path']
                    ip = data['ip']
                    
                    status_counts[status] += 1
                    ip_counts[ip] += 1
                    
                    if status.startswith('5') or status.startswith('4'):
                         endpoint_errors[f"{status} {path}"] += 1

    except FileNotFoundError:
        print(f"Error: File '{filepath}' not found.")
        sys.exit(1)

    print_report(total_lines, parsed_lines, status_counts, endpoint_errors, ip_counts, limit)

def print_report(total: int, parsed: int, statuses: Counter, errors: Counter, ips: Counter, limit: int) -> None:
    print(f"\n{'='*50}")
    print(f"Log Analysis Report")
    print(f"{'='*50}")
    print(f"Total lines processed: {total}")
    print(f"Successfully parsed:   {parsed}")
    print(f"Parse rate:            {(parsed/total*100) if total > 0 else 0:.1f}%\n")

    print(f"--- HTTP Status Code Breakdown ---")
    for status, count in statuses.most_common():
        print(f"HTTP {status}: {count} requests")
        
    print(f"\n--- Top {limit} Error Endpoints (4xx/5xx) ---")
    if not errors:
        print("No 4xx or 5xx errors found.")
    for err, count in errors.most_common(limit):
        print(f"{count:5d} occurrences: {err}")

    print(f"\n--- Top {limit} Client IPs by Volume ---")
    for ip, count in ips.most_common(limit):
        print(f"{count:5d} requests: {ip}")
    print(f"{'='*50}\n")

if __name__ == "__main__":
    args = parse_args()
    if args.format == "json":
        analyze_json_logs(args.logfile, args.limit)
    elif args.format == "nginx":
        analyze_nginx_logs(args.logfile, args.limit)
