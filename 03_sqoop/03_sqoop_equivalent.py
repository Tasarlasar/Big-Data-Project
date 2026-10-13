#!/usr/bin/env python3
"""
Sqoop-equivalent SQL → HDFS ingestion.
Big Data Computing CAT II – Project 1

Sqoop 1.4.7 is incompatible with Hadoop 3.5 (commons-cli API break), so this
script performs the same job Sqoop would: it reads each MySQL table over JDBC
with mapper-style parallel range splits and writes comma-delimited part files
straight into HDFS — mirroring `sqoop import --split-by ... -m N`.

This satisfies FR2 (SQL → HDFS) using an equivalent mechanism, as permitted
by the PRD.

Usage:
    python3 03_sqoop_equivalent.py --mappers 4
"""
import argparse
import subprocess
import sys
import os
import tempfile
from concurrent.futures import ThreadPoolExecutor

try:
    import pymysql
except ImportError:
    os.system("pip3 install pymysql -q")
    import pymysql

JAVA_HOME = "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
HDFS_BASE = "/user/bigdata/ecommerce/sqoop_import"

MYSQL = dict(host="localhost", port=3306, user="root", password="", database="olist_ecommerce")

# table -> (numeric split column or None, target subdir)
TABLES = {
    "customers":                         (None,                 "customers"),
    "sellers":                           (None,                 "sellers"),
    "products":                          (None,                 "products"),
    "product_category_name_translation": (None,                 "category_translation"),
    "orders":                            (None,                 "orders"),
    "order_items":                       ("order_item_id",      "order_items"),
    "order_payments":                    ("payment_sequential", "order_payments"),
    "order_reviews":                     (None,                 "order_reviews"),
    "geolocation":                       (None,                 "geolocation"),
}


def hdfs(*args):
    env = {**os.environ, "JAVA_HOME": JAVA_HOME}
    return subprocess.run(["hdfs", "dfs", *args], capture_output=True, text=True, env=env)


def csv_escape(val):
    if val is None:
        return "\\N"
    s = str(val)
    # Match Sqoop default: no quoting, escape embedded delimiters/newlines
    s = s.replace("\\", "\\\\").replace(",", "\\,").replace("\n", "\\n").replace("\r", "")
    return s


def fetch_range(table, split_col, lo, hi):
    """Fetch one split (mapper) and return list of CSV lines."""
    conn = pymysql.connect(**MYSQL)
    lines = []
    try:
        with conn.cursor() as cur:
            if split_col:
                cur.execute(f"SELECT * FROM {table} WHERE {split_col} >= %s AND {split_col} < %s", (lo, hi))
            else:
                cur.execute(f"SELECT * FROM {table}")
            for row in cur.fetchall():
                lines.append(",".join(csv_escape(v) for v in row))
    finally:
        conn.close()
    return lines


def import_table(table, split_col, subdir, mappers):
    target = f"{HDFS_BASE}/{subdir}"
    print(f"\n── Importing {table} → {target} ({'split='+split_col if split_col else 'single mapper'}) ──")

    # Fresh target dir (like sqoop --delete-target-dir)
    hdfs("-rm", "-r", "-f", target)
    hdfs("-mkdir", "-p", target)

    conn = pymysql.connect(**MYSQL)
    splits = []
    try:
        with conn.cursor() as cur:
            if split_col:
                cur.execute(f"SELECT MIN({split_col}), MAX({split_col}) FROM {table}")
                mn, mx = cur.fetchone()
                mn, mx = int(mn), int(mx)
                step = max(1, (mx - mn + 1) // mappers)
                b = mn
                while b <= mx:
                    splits.append((b, b + step))
                    b += step
            else:
                splits.append((None, None))
    finally:
        conn.close()

    # Run mappers in parallel
    all_parts = []
    with ThreadPoolExecutor(max_workers=mappers) as pool:
        futures = [pool.submit(fetch_range, table, split_col, lo, hi) for (lo, hi) in splits]
        for i, fut in enumerate(futures):
            lines = fut.result()
            # Write each mapper output as a part file into HDFS
            with tempfile.NamedTemporaryFile("w", suffix=".csv", delete=False) as tf:
                tf.write("\n".join(lines))
                if lines:
                    tf.write("\n")
                tmp_path = tf.name
            part_name = f"part-m-{i:05d}"
            hdfs("-put", "-f", tmp_path, f"{target}/{part_name}")
            os.unlink(tmp_path)
            all_parts.append(len(lines))

    total = sum(all_parts)
    print(f"   Imported {total:,} rows across {len(splits)} mapper(s): {all_parts}")
    return table, total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mappers", type=int, default=4)
    ap.add_argument("--password", default="")
    args = ap.parse_args()
    MYSQL["password"] = args.password

    print("=" * 70)
    print(" Sqoop-equivalent MySQL → HDFS import")
    print("=" * 70)

    results = []
    for table, (split_col, subdir) in TABLES.items():
        results.append(import_table(table, split_col, subdir, args.mappers))

    print("\n" + "=" * 70)
    print(" Import summary (rows written to HDFS as part-m-* files)")
    print("=" * 70)
    for table, total in results:
        print(f"  {table:<40} {total:>12,}")
    print("\nDone. Sqoop-style part files are now in HDFS alongside the raw CSVs.")


if __name__ == "__main__":
    main()
