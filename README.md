# Ops Diagnostics

A curated collection of diagnostic scripts and operational utilities built for Technical Support Engineers (TSEs), Application Support Analysts, and Reliability Engineers. This toolkit is designed to accelerate incident triage, isolate issues across the stack (Network, Application, System, Database), and provide structured evidence when escalating to engineering teams.

## Overview

Modern SaaS platforms require support professionals to rapidly navigate complex, distributed architectures. These tools are built to run safely in production or localized test environments to capture state without introducing instability.

### Core Modules

* **Network**: Scripts for verifying API health, payload sizes, latencies, and SSL certificate lifespans.
* **Logs**: Utilities for parsing structured and unstructured logs (Nginx, Apache, JSON) to aggregate error rates and identify fault patterns.
* **System**: Quick-snapshot scripts for capturing CPU, memory, disk I/O, and socket states during resource exhaustion events.
* **Database**: Lightweight testers for validating connectivity, connection pooling behavior, and baseline query latency.

## Prerequisites

- **OS**: Linux/macOS
- **Bash**: 4.0+
- **Python**: 3.8+
- **Dependencies**: Minimal standard libraries used where possible. Specific python requirements are listed in the individual module directories (e.g., `requests`, `psycopg2`).

## Usage Guidelines

1. **Safety First**: These scripts are designed to be non-destructive (read-only diagnostic operations). Always review the script contents before executing in a live customer environment.
2. **Execution**: Ensure scripts are executable (`chmod +x script_name`).
3. **Escalations**: Use the output of these tools as structured evidence in Jira/Linear tickets when escalating to Tier 3 or DevOps teams.

## Structure

```
.
├── network/
│   ├── check_api_health.sh
│   └── ssl_cert_check.sh
├── logs/
│   └── log_analyzer.py
├── system/
│   └── sys_health_dump.sh
└── db/
    └── db_latency_tester.py
```

## Contributing

For internal use. If adding new diagnostic tools, please ensure they follow the established pattern of failing safely and emitting structured, human-readable output.

---
*Maintained by Technical Operations & Infrastructure Lead.*
