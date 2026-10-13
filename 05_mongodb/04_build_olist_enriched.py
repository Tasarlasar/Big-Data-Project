#!/usr/bin/env python3
"""
Build olist_orders_enriched MongoDB collection.
Big Data Computing CAT II – Project 1

Reads the Olist CSVs, joins orders → order_items → order_payments → order_reviews,
and writes a denormalized document per order into MongoDB.

This demonstrates loading structured relational data into a NoSQL document store.

Usage:
    python3 04_build_olist_enriched.py --archive /path/to/archive
"""

import argparse
import csv
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

try:
    from pymongo import MongoClient, UpdateOne
    from pymongo.errors import BulkWriteError
except ImportError:
    sys.exit("pymongo not installed.  Run: pip install pymongo")


# ── Config ────────────────────────────────────────────────────────────────────
MONGO_URI    = "mongodb://localhost:27017"
DB_NAME      = "ecommerce_bigdata"
COLLECTION   = "olist_orders_enriched"
BATCH_SIZE   = 1000


# ── CSV helpers ───────────────────────────────────────────────────────────────
def load_csv(path: Path, key: str | None = None) -> dict | list:
    """Load a CSV file.  If key is given, returns a dict keyed by that column."""
    rows = []
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            rows.append({k.strip('"').strip(): v.strip('"') for k, v in row.items()})
    if key:
        return {r[key]: r for r in rows}
    return rows


def load_csv_multi(path: Path, key: str) -> dict[str, list]:
    """Load a CSV into a dict mapping key → list of rows (one-to-many)."""
    result: dict[str, list] = defaultdict(list)
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            row = {k.strip('"').strip(): v.strip('"') for k, v in row.items()}
            result[row[key]].append(row)
    return result


def safe_float(v: str) -> float | None:
    try:
        return float(v) if v else None
    except ValueError:
        return None


def safe_int(v: str) -> int | None:
    try:
        return int(v) if v else None
    except ValueError:
        return None


# ── Main ──────────────────────────────────────────────────────────────────────
def main(archive_dir: Path) -> None:
    print("Loading CSVs …")
    orders     = load_csv(archive_dir / "olist_orders_dataset.csv",    key="order_id")
    items      = load_csv_multi(archive_dir / "olist_order_items_dataset.csv",    "order_id")
    payments   = load_csv_multi(archive_dir / "olist_order_payments_dataset.csv", "order_id")
    reviews    = load_csv(archive_dir / "olist_order_reviews_dataset.csv", key="order_id")
    customers  = load_csv(archive_dir / "olist_customers_dataset.csv",  key="customer_id")
    products   = load_csv(archive_dir / "olist_products_dataset.csv",   key="product_id")
    cat_trans  = load_csv(archive_dir / "product_category_name_translation.csv",
                          key="product_category_name")

    print(f"  orders:    {len(orders):,}")
    print(f"  items:     {sum(len(v) for v in items.values()):,}")
    print(f"  payments:  {sum(len(v) for v in payments.values()):,}")
    print(f"  reviews:   {len(reviews):,}")

    client = MongoClient(MONGO_URI)
    col    = client[DB_NAME][COLLECTION]
    col.delete_many({})   # clean slate

    print("\nBuilding enriched documents …")
    ops: list[UpdateOne] = []
    total = 0

    for order_id, order in orders.items():
        cust = customers.get(order["customer_id"], {})

        # ── items ──────────────────────────────────────────────────────────
        order_items_list = []
        for it in items.get(order_id, []):
            prod = products.get(it["product_id"], {})
            cat_en = cat_trans.get(prod.get("product_category_name", ""), {})
            order_items_list.append({
                "order_item_id":           safe_int(it["order_item_id"]),
                "product_id":              it["product_id"],
                "seller_id":               it["seller_id"],
                "price":                   safe_float(it["price"]),
                "freight_value":           safe_float(it["freight_value"]),
                "product_category":        prod.get("product_category_name"),
                "product_category_en":     cat_en.get("product_category_name_english"),
                "shipping_limit_date":     it.get("shipping_limit_date"),
            })

        # ── payments ───────────────────────────────────────────────────────
        order_payments_list = []
        for pay in payments.get(order_id, []):
            order_payments_list.append({
                "payment_sequential":   safe_int(pay["payment_sequential"]),
                "payment_type":         pay["payment_type"],
                "payment_installments": safe_int(pay["payment_installments"]),
                "payment_value":        safe_float(pay["payment_value"]),
            })

        total_payment = sum(
            p["payment_value"] for p in order_payments_list
            if p["payment_value"] is not None
        )

        # ── review ─────────────────────────────────────────────────────────
        rev = reviews.get(order_id, {})
        review_doc: dict[str, Any] | None = None
        if rev:
            review_doc = {
                "review_id":    rev.get("review_id"),
                "review_score": safe_int(rev.get("review_score", "")),
                "comment_title":   rev.get("review_comment_title") or None,
                "comment_message": rev.get("review_comment_message") or None,
                "creation_date":   rev.get("review_creation_date") or None,
            }

        # ── full document ──────────────────────────────────────────────────
        doc: dict[str, Any] = {
            "order_id":                   order_id,
            "customer_id":                order["customer_id"],
            "customer_city":              cust.get("customer_city"),
            "customer_state":             cust.get("customer_state"),
            "order_status":               order["order_status"],
            "order_purchase_timestamp":   order.get("order_purchase_timestamp") or None,
            "order_approved_at":          order.get("order_approved_at") or None,
            "order_delivered_carrier_date":  order.get("order_delivered_carrier_date") or None,
            "order_delivered_customer_date": order.get("order_delivered_customer_date") or None,
            "order_estimated_delivery_date": order.get("order_estimated_delivery_date") or None,
            "items":         order_items_list,
            "payments":      order_payments_list,
            "total_payment": round(total_payment, 2),
            "review":        review_doc,
        }

        ops.append(UpdateOne({"order_id": order_id}, {"$set": doc}, upsert=True))

        if len(ops) >= BATCH_SIZE:
            try:
                col.bulk_write(ops, ordered=False)
            except BulkWriteError as bwe:
                print(f"  BulkWriteError: {bwe.details.get('nInserted', 0)} inserted, errors skipped")
            total += len(ops)
            ops = []
            print(f"  Written {total:,} documents …", end="\r")

    if ops:
        col.bulk_write(ops, ordered=False)
        total += len(ops)

    print(f"\nTotal documents written: {total:,}")
    print(f"Collection count:        {col.count_documents({}):,}")
    client.close()
    print("Done.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", default="./archive",
                        help="Path to the Olist archive directory")
    args = parser.parse_args()
    main(Path(args.archive))
