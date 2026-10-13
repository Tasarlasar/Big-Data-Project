#!/usr/bin/env python3
"""
Local Python Analytics – E-Commerce Big Data Pipeline
Big Data Computing CAT II – Project 1

Runs all 13 analytics queries directly on the Olist CSVs using pandas.
This produces real output when Hive is not yet configured.
Results are also written to HDFS (as CSV) via subprocess hdfs dfs -put.

Usage:
    python3 local_analytics.py --archive /path/to/archive --hdfs
"""

import argparse
import csv
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

try:
    import pandas as pd
    import numpy as np
except ImportError:
    sys.exit("Run:  pip3 install pandas numpy")

HDFS_ROOT = "/user/bigdata/ecommerce/analytics"
OUTPUT_DIR = Path("/tmp/ecommerce_analytics")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

SEP = "═" * 70


def load(archive: Path, filename: str) -> pd.DataFrame:
    path = archive / filename
    print(f"  Loading {filename} ({path.stat().st_size // 1024:,} KB) …")
    return pd.read_csv(path, low_memory=False)


def save(df: pd.DataFrame, name: str, upload_hdfs: bool) -> None:
    out = OUTPUT_DIR / f"{name}.csv"
    df.to_csv(out, index=False)
    print(f"  Saved  → {out}")
    if upload_hdfs:
        hdfs_path = f"{HDFS_ROOT}/hive/{name.replace('result_', '')}/"
        r = subprocess.run(
            ["hdfs", "dfs", "-put", "-f", str(out), hdfs_path],
            capture_output=True, text=True,
            env={**__import__("os").environ,
                 "JAVA_HOME": "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"}
        )
        if r.returncode == 0:
            print(f"  HDFS   → {hdfs_path}")
        else:
            print(f"  HDFS upload skipped: {r.stderr.strip()[:80]}")


def fmt(df: pd.DataFrame) -> str:
    return df.to_string(index=False)


# ─────────────────────────────────────────────────────────────────────────────

def run(archive: Path, upload_hdfs: bool) -> None:
    print(f"\n{'▶ Loading datasets':}")
    customers    = load(archive, "olist_customers_dataset.csv")
    orders       = load(archive, "olist_orders_dataset.csv")
    order_items  = load(archive, "olist_order_items_dataset.csv")
    payments     = load(archive, "olist_order_payments_dataset.csv")
    reviews      = load(archive, "olist_order_reviews_dataset.csv")
    products     = load(archive, "olist_products_dataset.csv")
    sellers      = load(archive, "olist_sellers_dataset.csv")
    cat_trans    = load(archive, "product_category_name_translation.csv")

    # ── Clean column names (strip quotes) ────────────────────────────────────
    for df in [customers, orders, order_items, payments, reviews,
               products, sellers, cat_trans]:
        df.columns = df.columns.str.strip('"').str.strip()

    # ── Parse timestamps ──────────────────────────────────────────────────────
    for col in ["order_purchase_timestamp", "order_delivered_customer_date",
                "order_estimated_delivery_date"]:
        orders[col] = pd.to_datetime(orders[col], errors="coerce")

    # ── Delivered orders only ─────────────────────────────────────────────────
    delivered = orders[orders["order_status"] == "delivered"]

    # ── Join helpers ──────────────────────────────────────────────────────────
    items_products = order_items.merge(products, on="product_id", how="left") \
                                .merge(cat_trans, on="product_category_name", how="left")
    items_del = items_products.merge(
        delivered[["order_id", "customer_id", "order_purchase_timestamp",
                   "order_delivered_customer_date", "order_estimated_delivery_date"]],
        on="order_id", how="inner")

    # ──────────────────────────────────────────────────────────────────────────
    # Q1. Total Orders, Revenue, Avg Order Value
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q1. Total Orders, Revenue, and Average Order Value\n{SEP}")
    pay_del = payments[payments["order_id"].isin(delivered["order_id"])]
    order_totals = pay_del.groupby("order_id")["payment_value"].sum()
    q1 = pd.DataFrame({
        "total_orders":      [delivered["order_id"].nunique()],
        "unique_customers":  [delivered["customer_id"].nunique()],
        "total_revenue":     [round(order_totals.sum(), 2)],
        "avg_order_value":   [round(order_totals.mean(), 2)],
        "median_order_value":[round(order_totals.median(), 2)],
    })
    print(fmt(q1))
    save(q1, "result_q1_overview", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q2. Revenue by Product Category (top 15)
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q2. Revenue by Product Category (Top 15)\n{SEP}")
    q2 = items_del.groupby("product_category_name_english").agg(
        order_count=("order_id", "nunique"),
        units_sold=("order_item_id", "count"),
        total_revenue=("price", "sum"),
        avg_price=("price", "mean"),
    ).round(2).sort_values("total_revenue", ascending=False).head(15).reset_index()
    q2.rename(columns={"product_category_name_english": "category"}, inplace=True)
    print(fmt(q2))
    save(q2, "result_q2_revenue_by_category", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q3. Top 20 Best-Selling Products
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q3. Top 20 Best-Selling Products\n{SEP}")
    q3 = items_del.groupby(["product_id", "product_category_name_english"]).agg(
        units_sold=("order_item_id", "count"),
        total_revenue=("price", "sum"),
        avg_price=("price", "mean"),
    ).round(2).sort_values("units_sold", ascending=False).head(20).reset_index()
    q3.rename(columns={"product_category_name_english": "category"}, inplace=True)
    print(fmt(q3))
    save(q3, "result_q3_top_products", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q4. Payment Method Distribution
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q4. Payment Method Distribution\n{SEP}")
    q4 = payments.groupby("payment_type").agg(
        order_count=("order_id", "nunique"),
        total_value=("payment_value", "sum"),
        avg_installments=("payment_installments", "mean"),
    ).round(2).reset_index().sort_values("order_count", ascending=False)
    q4["pct_of_orders"] = (q4["order_count"] / q4["order_count"].sum() * 100).round(2)
    print(fmt(q4))
    save(q4, "result_q4_payment_methods", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q5. Customer Lifetime Value – Top 20
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q5. Top 20 Customers by Lifetime Value\n{SEP}")
    cust_orders = delivered.merge(customers, on="customer_id", how="left")
    cust_pay    = cust_orders.merge(payments, on="order_id", how="left")
    q5 = cust_pay.groupby(["customer_unique_id", "customer_state"]).agg(
        total_orders=("order_id", "nunique"),
        lifetime_value=("payment_value", "sum"),
        avg_order_value=("payment_value", "mean"),
    ).round(2).sort_values("lifetime_value", ascending=False).head(20).reset_index()
    print(fmt(q5))
    save(q5, "result_q5_customer_ltv", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q6. Average Review Score by Category
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q6. Review Score Distribution by Category\n{SEP}")
    rev_items = reviews.merge(orders[["order_id"]], on="order_id", how="inner") \
                       .merge(order_items[["order_id", "product_id"]], on="order_id", how="left") \
                       .merge(products[["product_id", "product_category_name"]], on="product_id", how="left") \
                       .merge(cat_trans, on="product_category_name", how="left")
    q6 = rev_items.groupby("product_category_name_english").agg(
        review_count=("review_id", "count"),
        avg_score=("review_score", "mean"),
        five_star=("review_score", lambda x: (x == 5).sum()),
        four_star=("review_score", lambda x: (x == 4).sum()),
        low_score=("review_score", lambda x: (x <= 2).sum()),
    ).round(2).sort_values("review_count", ascending=False).head(20).reset_index()
    q6.rename(columns={"product_category_name_english": "category"}, inplace=True)
    print(fmt(q6))
    save(q6, "result_q6_reviews_by_category", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q7. High Sales + Poor Ratings
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q7. High-Sales Products with Poor Ratings (<3.0)\n{SEP}")
    merged7 = items_del.merge(reviews[["order_id", "review_score"]], on="order_id", how="left")
    q7 = merged7.groupby(["product_id", "product_category_name_english"]).agg(
        units_sold=("order_item_id", "count"),
        total_revenue=("price", "sum"),
        avg_review_score=("review_score", "mean"),
    ).round(2).reset_index()
    q7 = q7[(q7["units_sold"] >= 10) & (q7["avg_review_score"] < 3.0)] \
           .sort_values("units_sold", ascending=False).head(20)
    q7.rename(columns={"product_category_name_english": "category"}, inplace=True)
    print(fmt(q7))
    save(q7, "result_q7_high_sales_poor_rating", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q8. Monthly Order Trend
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q8. Monthly Order Trend\n{SEP}")
    del_pay = delivered.merge(payments, on="order_id", how="left")
    del_pay["year_month"] = del_pay["order_purchase_timestamp"].dt.to_period("M").astype(str)
    q8 = del_pay.groupby("year_month").agg(
        order_count=("order_id", "nunique"),
        unique_customers=("customer_id", "nunique"),
        monthly_revenue=("payment_value", "sum"),
    ).round(2).reset_index().sort_values("year_month")
    print(fmt(q8))
    save(q8, "result_q8_monthly_trend", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q9. Delivery Time vs Review Score
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q9. Delivery Time vs Review Score\n{SEP}")
    del_rev = delivered.merge(reviews[["order_id", "review_score"]], on="order_id", how="inner")
    del_rev["delivery_days"] = (
        del_rev["order_delivered_customer_date"] - del_rev["order_purchase_timestamp"]
    ).dt.days
    del_rev = del_rev[del_rev["delivery_days"].notna() & (del_rev["delivery_days"] >= 0)]
    q9 = del_rev.groupby("review_score").agg(
        orders=("order_id", "count"),
        avg_delivery_days=("delivery_days", "mean"),
        min_delivery_days=("delivery_days", "min"),
        max_delivery_days=("delivery_days", "max"),
    ).round(1).reset_index()
    print(fmt(q9))
    save(q9, "result_q9_delivery_vs_score", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q10. On-Time vs Late Delivery Rate
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q10. On-Time vs Late Delivery\n{SEP}")
    del_rev2 = delivered.copy()
    del_rev2["delivery_status"] = np.where(
        del_rev2["order_delivered_customer_date"] <= del_rev2["order_estimated_delivery_date"],
        "On Time", "Late"
    )
    del_rev2 = del_rev2.merge(reviews[["order_id", "review_score"]], on="order_id", how="left")
    q10 = del_rev2.groupby("delivery_status").agg(
        order_count=("order_id", "count"),
        avg_review_score=("review_score", "mean"),
    ).round(2).reset_index()
    q10["pct"] = (q10["order_count"] / q10["order_count"].sum() * 100).round(1)
    print(fmt(q10))
    save(q10, "result_q10_delivery_rate", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q11. Top 20 Sellers by Revenue
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q11. Top 20 Sellers by Revenue\n{SEP}")
    items_del_rev = items_del.merge(reviews[["order_id", "review_score"]], on="order_id", how="left") \
                             .merge(sellers, on="seller_id", how="left")
    q11 = items_del_rev.groupby(["seller_id", "seller_state", "seller_city"]).agg(
        orders_fulfilled=("order_id", "nunique"),
        items_sold=("order_item_id", "count"),
        total_revenue=("price", "sum"),
        avg_review_score=("review_score", "mean"),
    ).round(2).sort_values("total_revenue", ascending=False).head(20).reset_index()
    print(fmt(q11))
    save(q11, "result_q11_seller_performance", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q12. Review Score Distribution (overall)
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q12. Overall Review Score Distribution\n{SEP}")
    q12 = reviews.groupby("review_score").agg(
        count=("review_id", "count"),
    ).reset_index()
    q12["pct"] = (q12["count"] / q12["count"].sum() * 100).round(2)
    print(fmt(q12))
    save(q12, "result_q12_review_distribution", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    # Q13. State-Level Sales Heatmap
    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{SEP}\n Q13. Revenue by Customer State\n{SEP}")
    state_data = delivered.merge(customers[["customer_id", "customer_state"]], on="customer_id") \
                          .merge(payments, on="order_id")
    q13 = state_data.groupby("customer_state").agg(
        order_count=("order_id", "nunique"),
        total_spend=("payment_value", "sum"),
        unique_customers=("customer_id", "nunique"),
    ).round(2).sort_values("total_spend", ascending=False).reset_index()
    print(fmt(q13))
    save(q13, "result_q13_state_heatmap", upload_hdfs)

    # ──────────────────────────────────────────────────────────────────────────
    print(f"\n{'═'*70}")
    print(f" All 13 analytics queries complete.")
    print(f" CSV results saved to: {OUTPUT_DIR}/")
    if upload_hdfs:
        print(f" HDFS location:         {HDFS_ROOT}/hive/")
    print(f"{'═'*70}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", default="./archive")
    parser.add_argument("--hdfs", action="store_true", help="Upload results to HDFS")
    args = parser.parse_args()
    run(Path(args.archive), args.hdfs)
