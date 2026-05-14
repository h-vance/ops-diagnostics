#!/usr/bin/env python3
"""
db_latency_tester.py

Purpose: A lightweight diagnostic tool to measure basic database connectivity 
and simple query latency from the application tier. 
This helps isolate network/DB load issues from application logic.

Prerequisites: 
    pip install psycopg2-binary (for PostgreSQL)

Usage:
    python3 db_latency_tester.py --dsn "postgres://user:pass@host:5432/db" [--iterations 5]

Note: Currently implemented for PostgreSQL. Can be extended for MySQL, etc.
"""

import sys
import time
import argparse
import statistics

try:
    import psycopg2
except ImportError:
    print("Error: psycopg2 library is required.")
    print("Please install it using: pip install psycopg2-binary")
    sys.exit(1)

def parse_args():
    parser = argparse.ArgumentParser(description="Test database connectivity and simple query latency.")
    parser.add_argument("--dsn", required=True, help="Database Connection String (DSN)")
    parser.add_argument("--query", default="SELECT 1", help="Query to run (default: SELECT 1)")
    parser.add_argument("--iterations", type=int, default=5, help="Number of queries to run (default: 5)")
    return parser.parse_args()

def test_connection_and_latency(dsn: str, query: str, iterations: int):
    latencies = []
    
    print(f"Attempting to connect to database...")
    try:
        # Measure connection time
        conn_start = time.time()
        conn = psycopg2.connect(dsn, connect_timeout=5)
        conn_end = time.time()
        print(f"[OK] Connected in {(conn_end - conn_start) * 1000:.2f} ms")
        
    except psycopg2.OperationalError as e:
        print(f"[ERROR] Failed to connect to database: {e}")
        sys.exit(2)

    try:
        with conn.cursor() as cur:
            print(f"Running '{query}' {iterations} times...")
            for i in range(iterations):
                start = time.time()
                cur.execute(query)
                cur.fetchone() # Fetch the result to complete the cycle
                end = time.time()
                
                latency_ms = (end - start) * 1000
                latencies.append(latency_ms)
                print(f"  Iteration {i+1}: {latency_ms:.2f} ms")
                time.sleep(0.1) # Small pause between queries
                
    except psycopg2.Error as e:
         print(f"[ERROR] Query execution failed: {e}")
         sys.exit(3)
    finally:
        conn.close()
        print("Connection closed.")

    # Calculate and display summary statistics
    if latencies:
        print("\n--- Latency Summary ---")
        print(f"Min:    {min(latencies):.2f} ms")
        print(f"Max:    {max(latencies):.2f} ms")
        print(f"Avg:    {statistics.mean(latencies):.2f} ms")
        if len(latencies) > 1:
            print(f"Median: {statistics.median(latencies):.2f} ms")

if __name__ == "__main__":
    args = parse_args()
    
    # Hide password in output
    safe_dsn = args.dsn
    if "@" in safe_dsn and ":" in safe_dsn:
        # naive redaction for display purposes
        parts = safe_dsn.split("@")
        cred_parts = parts[0].split(":")
        if len(cred_parts) >= 3: # scheme://user:pass
             safe_dsn = f"{cred_parts[0]}:{cred_parts[1]}:***@{parts[1]}"
             
    print(f"Targeting: {safe_dsn}")
    test_connection_and_latency(args.dsn, args.query, args.iterations)
