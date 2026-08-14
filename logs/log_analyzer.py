#!/usr/bin/env python3
"""Aggregate status codes, error endpoints, and client IPs from JSON or Nginx logs."""

import argparse
import json
import re
import sys
from collections import Counter
from collections.abc import Callable

LogParser = Callable[[str], tuple[str, str, str] | None]
NGINX_PATTERN = re.compile(
    r'(?P<ip>\S+) \S+ \S+ \[[^\]]+\] "\S+ (?P<path>\S+) \S+" (?P<status>\d{3}) \d+ ".*?" ".*?"'
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Diagnostic log analyzer for SaaS support triage.")
    parser.add_argument("logfile", help="Path to the log file to analyze")
    parser.add_argument("--format", choices=["json", "nginx"], default="json")
    parser.add_argument("--limit", type=int, default=10)
    return parser.parse_args()


def parse_json_line(line: str) -> tuple[str, str, str] | None:
    try:
        data = json.loads(line)
    except json.JSONDecodeError:
        return None

    return (
        str(data.get("status", data.get("statusCode", "unknown"))),
        data.get("path", data.get("url", "unknown")),
        data.get("ip", data.get("client_ip", "unknown")),
    )


def parse_nginx_line(line: str) -> tuple[str, str, str] | None:
    match = NGINX_PATTERN.match(line)
    if not match:
        return None

    data = match.groupdict()
    return data["status"], data["path"], data["ip"]


def analyze_logs(filepath: str, parser: LogParser, limit: int) -> None:
    statuses = Counter()
    errors = Counter()
    ips = Counter()
    total = 0
    parsed = 0

    try:
        with open(filepath) as file:
            for line in file:
                total += 1
                record = parser(line)
                if not record:
                    continue

                parsed += 1
                status, path, ip = record
                statuses[status] += 1
                ips[ip] += 1
                if status.startswith(("4", "5")):
                    errors[f"{status} {path}"] += 1
    except FileNotFoundError:
        print(f"Error: File '{filepath}' not found.")
        sys.exit(1)

    print_report(total, parsed, statuses, errors, ips, limit)


def print_report(total: int, parsed: int, statuses: Counter, errors: Counter, ips: Counter, limit: int) -> None:
    print(f"\n{'=' * 50}")
    print("Log Analysis Report")
    print(f"{'=' * 50}")
    print(f"Total lines processed: {total}")
    print(f"Successfully parsed:   {parsed}")
    print(f"Parse rate:            {(parsed / total * 100) if total else 0:.1f}%\n")

    print("--- HTTP Status Code Breakdown ---")
    for status, count in statuses.most_common():
        print(f"HTTP {status}: {count} requests")

    print(f"\n--- Top {limit} Error Endpoints (4xx/5xx) ---")
    if not errors:
        print("No 4xx or 5xx errors found.")
    for error, count in errors.most_common(limit):
        print(f"{count:5d} occurrences: {error}")

    print(f"\n--- Top {limit} Client IPs by Volume ---")
    for ip, count in ips.most_common(limit):
        print(f"{count:5d} requests: {ip}")
    print(f"{'=' * 50}\n")


if __name__ == "__main__":
    args = parse_args()
    analyze_logs(args.logfile, {"json": parse_json_line, "nginx": parse_nginx_line}[args.format], args.limit)
