# Ops Diagnostics

> **Diagnostic scripts built to accelerate incident triage and reduce Mean Time to Resolution (MTTR).**

[![Python](https://www.shieldcn.dev/badge/Python-3.8+-3776AB.svg?variant=default&logo=Python&logoColor=FFFFFF&size=xs)](https://python.org)&nbsp;[![GNU Bash](https://www.shieldcn.dev/badge/GNU%20Bash-4EAA25.svg?variant=default&logo=GNU+Bash&logoColor=FFFFFF&size=xs)](https://www.gnu.org/software/bash/)&nbsp;[![Linux](https://www.shieldcn.dev/badge/Linux-222222.svg?variant=default&logo=Linux&logoColor=FCC624&size=xs)](https://kernel.org)

---

## The Problem

**The Symptom:** Manual verification of production application services was slowing down initial ticket triage and increasing MTTR. Support teams needed a faster way to confirm if a reported outage was a localized user issue or a broader service degradation.

**The Investigation:** During incident response, engineers were manually running ad-hoc `curl` commands, grepping unstructured logs, and SSHing into multiple hosts to check resource states, all before even confirming whether the reported service was actually degraded.

**The Resolution:** Developed lightweight diagnostic scripts to automatically ping endpoints, parse health status, profile system resources, and scan application logs for recurring error patterns. These tools reduced manual verification time from ~15 minutes to under 60 seconds and accelerated engineering escalations with structured, evidence-backed output.

---

## Core Modules

### `network/`: Connectivity & Certificate Diagnostics

| Script | Purpose |
| ------ | ------- |
| [`check_api_health.sh`](network/check_api_health.sh) | Hit a target endpoint and emit HTTP status, response timing, DNS, TLS, and payload size as curl JSON metrics |
| [`ssl_cert_check.sh`](network/ssl_cert_check.sh) | Verify SSL/TLS certificate validity and warn when expiration is within 14 days |

### `logs/`: Log Analysis & Error Profiling

| Script | Purpose |
| ------ | ------- |
| [`log_analyzer.py`](logs/log_analyzer.py) | Parse structured (JSON) or standard Nginx access logs to aggregate HTTP status codes, identify high-frequency error endpoints, and profile top client IPs |

### `system/`: Resource Snapshot During Incidents

| Script | Purpose |
| ------ | ------- |
| [`sys_health_dump.sh`](system/sys_health_dump.sh) | Capture a point-in-time snapshot of CPU, memory, disk, top processes, network connections, and kernel messages, designed to preserve transient state during active incidents |

### Database Connectivity & Latency Baseline

Use the native database client from the app tier:

```bash
psql "$DATABASE_URL" -c "\\timing on" -c "SELECT 1"
```

---

## Usage

```bash
# API Health Check: is the service down or just slow?
./network/check_api_health.sh https://api.example.com/v1/health 5

# SSL Certificate: rule out expired certs during outage escalation
./network/ssl_cert_check.sh example.com 443

# Log Analysis: surface error patterns for ticket evidence
python3 logs/log_analyzer.py /var/log/nginx/access.log --format nginx --limit 15

# System Snapshot: capture transient state during an active incident
./system/sys_health_dump.sh

# DB Latency: baseline query performance from the app tier
psql "$DATABASE_URL" -c "\\timing on" -c "SELECT 1"
```

## Prerequisites

- **OS:** Linux / macOS
- **Bash:** 4.0+
- **Python:** 3.8+ (standard library only)
- **Optional:** `psql` for database latency checks

## Safety

All scripts are **read-only diagnostic operations**. They do not modify system state, write to production paths, or require elevated privileges (except `dmesg` in the system dump). Always review script contents before executing in a live customer environment.

---

## Related Repositories

| Repository | Description |
| ---------- | ----------- |
| [**log-rotation-maintenance**](https://github.com/h-vance/log-rotation-maintenance) | Automated Bash scripts for log rotation, compression, and storage cleanup on Linux servers |
| [**cloud-operations-runbook**](https://github.com/h-vance/cloud-operations-runbook) | 15+ standardized SOPs and runbooks covering compute, networking, identity, and application troubleshooting |

---

Maintained by a Technical Support Engineer focused on operational reliability and incident response.
