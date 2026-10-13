#!/usr/bin/env python3
"""
Python Analytics - E-Commerce Big Data Pipeline
Big Data Computing CAT II - Project 1

Reads PIG and HDFS outputs and runs analytics using Python/pandas.
This avoids Hive/MapReduce compatibility issues on macOS.
"""

import os
import subprocess
import pandas as pd
from io import StringIO

HDFS_BASE = "/user/bigdata/ecommerce"
OUTPUT_DIR = "/Users/home/College/Big Data Computing/E-commerce/08_run/python_outputs"

os.makedirs(OUTPUT_DIR, exist_ok=True)

def hdfs_read(path):
    result = subprocess.run(["hdfs", "dfs", "-cat", path], capture_output=True, text=True)
    return result.stdout

def hdfs_ls(path):
    result = subprocess.run(["hdfs", "dfs", "-ls", path], capture_output=True, text=True)
    return result.stdout

def read_hdfs_csv(hdfs_path, header=True, column_names=None):
    ls_output = hdfs_ls(hdfs_path)
    part_files = []
    for line in ls_output.strip().split('\n'):
        if 'part-' in line and ('-00000' in line or '-00001' in line or '-00002' in line):
            parts = line.split()
            if len(parts) >= 8:
                part_files.append(parts[-1])
    
    if not part_files:
        try:
            csv_names = ['olist_orders_dataset.csv', 'olist_order_items_dataset.csv', 
                        'olist_order_payments_dataset.csv', 'olist_products_dataset.csv',
                        'olist_customers_dataset.csv', 'olist_sellers_dataset.csv',
                        'olist_geolocation_dataset.csv', 'olist_order_reviews_dataset.csv',
                        'product_category_name_translation.csv']
            for csv_name in csv_names:
                full_path = hdfs_path.rstrip('/') + '/' + csv_name
                csv_data = hdfs_read(full_path)
                if csv_data.strip():
                    return pd.read_csv(StringIO(csv_data), header=0, quotechar='"')
            csv_data = hdfs_read(hdfs_path)
            if csv_data.strip():
                return pd.read_csv(StringIO(csv_data), header=0, quotechar='"')
        except Exception as e:
            print(f"  Warning: Could not read {hdfs_path}: {e}")
        return pd.DataFrame()
    
    dfs = []
    for part_file in part_files:
        try:
            csv_data = hdfs_read(part_file)
            if csv_data.strip():
                df = pd.read_csv(StringIO(csv_data), header=None, quotechar='"', on_bad_lines='warn')
                if column_names:
                    df.columns = column_names
                dfs.append(df)
        except Exception as e:
            print(f"  Warning: Could not read {part_file}: {e}")
    
    if dfs:
        return pd.concat(dfs, ignore_index=True)
    return pd.DataFrame()

print("=" * 70)
print(" E-Commerce Analytics with Python (pandas)")
print("=" * 70)

PIG_COL_NAMES = {
    'orders_joined': ['order_id', 'customer_id', 'order_status', 'purchase_ts', 'delivered_ts', 
                      'estimated_ts', 'item_id', 'product_id', 'seller_id', 'item_price', 
                      'freight_value', 'total_item_cost', 'category_pt', 'category_en', 'order_total_payment'],
    'revenue_by_category': ['category', 'item_count', 'total_revenue', 'avg_item_price', 'min_price',
                            'max_price', 'total_freight', 'distinct_orders', 'distinct_products'],
    'top_products': ['product_id', 'category_en', 'units_sold', 'total_revenue', 'avg_price', 
                     'seller_count', 'order_count']
}

print("\n── Loading data from HDFS ──")

orders_df = read_hdfs_csv(f"{HDFS_BASE}/raw/structured/orders")
print(f"  orders: {len(orders_df):,} rows")
order_items_df = read_hdfs_csv(f"{HDFS_BASE}/raw/structured/order_items")
print(f"  order_items: {len(order_items_df):,} rows")
payments_df = read_hdfs_csv(f"{HDFS_BASE}/raw/structured/order_payments")
print(f"  order_payments: {len(payments_df):,} rows")
products_df = read_hdfs_csv(f"{HDFS_BASE}/raw/structured/products")
print(f"  products: {len(products_df):,} rows")
customers_df = read_hdfs_csv(f"{HDFS_BASE}/raw/structured/customers")
print(f"  customers: {len(customers_df):,} rows")
sellers_df = read_hdfs_csv(f"{HDFS_BASE}/raw/structured/sellers")
print(f"  sellers: {len(sellers_df):,} rows")
geolocation_df = read_hdfs_csv(f"{HDFS_BASE}/raw/structured/geolocation")
print(f"  geolocation: {len(geolocation_df):,} rows")
category_trans_df = read_hdfs_csv(f"{HDFS_BASE}/raw/structured/category_translation")
print(f"  category_translation: {len(category_trans_df):,} rows")
order_reviews_df = read_hdfs_csv(f"{HDFS_BASE}/raw/structured/order_reviews")
print(f"  order_reviews: {len(order_reviews_df):,} rows")
orders_joined_df = read_hdfs_csv(f"{HDFS_BASE}/processed/orders_joined", column_names=PIG_COL_NAMES.get('orders_joined'))
print(f"  orders_joined: {len(orders_joined_df):,} rows")
revenue_by_cat_df = read_hdfs_csv(f"{HDFS_BASE}/processed/revenue_by_category", column_names=PIG_COL_NAMES.get('revenue_by_category'))
print(f"  revenue_by_category: {len(revenue_by_cat_df):,} rows")
top_products_df = read_hdfs_csv(f"{HDFS_BASE}/processed/top_products", column_names=PIG_COL_NAMES.get('top_products'))
print(f"  top_products: {len(top_products_df):,} rows")
print(f"\n  Data loaded successfully.")

print("\n── Q1. Total Orders, Revenue, and Average Order Value ──")
delivered_orders = orders_df[orders_df['order_status'] == 'delivered']
q1 = delivered_orders.merge(payments_df[['order_id', 'payment_value']], on='order_id')
q1_result = pd.DataFrame([{
    'total_orders': q1['order_id'].nunique(),
    'total_revenue': round(q1['payment_value'].sum(), 2),
    'avg_order_value': round(q1['payment_value'].mean(), 2),
    'unique_customers': q1['customer_id'].nunique()
}])
q1_result.to_csv(f"{OUTPUT_DIR}/q1_total_orders_revenue.csv", index=False)
print(q1_result.to_string(index=False))

print("\n── Q2. Revenue by Product Category (English names, top 15) ──")
q2 = order_items_df.merge(products_df[['product_id', 'product_category_name']], on='product_id')
q2 = q2.merge(category_trans_df, on='product_category_name', how='left')
q2['category'] = q2['product_category_name_english'].fillna('Unknown')
q2_result = q2.groupby('category').agg(
    order_count=('order_id', 'nunique'),
    item_count=('product_id', 'count'),
    total_revenue=('price', 'sum'),
    avg_price=('price', 'mean')
).reset_index()
q2_result['total_revenue'] = q2_result['total_revenue'].round(2)
q2_result['avg_price'] = q2_result['avg_price'].round(2)
q2_result = q2_result.sort_values('total_revenue', ascending=False).head(15)
q2_result.to_csv(f"{OUTPUT_DIR}/q2_revenue_by_category.csv", index=False)
print(q2_result.to_string(index=False))

print("\n── Q3. Top Products by Total Revenue (top 50) ──")
q3_result = orders_joined_df.groupby(['product_id', 'category_en']).agg(
    units_sold=('order_id', 'count'),
    total_revenue=('total_item_cost', 'sum'),
    avg_price=('item_price', 'mean')
).reset_index()
q3_result['total_revenue'] = q3_result['total_revenue'].round(2)
q3_result['avg_price'] = q3_result['avg_price'].round(2)
q3_result = q3_result.sort_values('total_revenue', ascending=False).head(50)
q3_result.to_csv(f"{OUTPUT_DIR}/q3_top_products_revenue.csv", index=False)
print(q3_result.head(10).to_string(index=False))

print("\n── Q4. Payment Methods Distribution ──")
q4_result = payments_df.groupby('payment_type').agg(
    count=('order_id', 'count'),
    order_count=('order_id', 'nunique'),
    total_value=('payment_value', 'sum')
).reset_index()
q4_result['total_value'] = q4_result['total_value'].round(2)
q4_result = q4_result.sort_values('count', ascending=False)
q4_result.to_csv(f"{OUTPUT_DIR}/q4_payment_methods.csv", index=False)
print(q4_result.to_string(index=False))

print("\n── Q5. Customer Lifetime Value (CLV) ──")
order_values = payments_df.groupby('order_id')['payment_value'].sum().reset_index()
order_values.columns = ['order_id', 'order_value']
q5 = order_values.merge(orders_df[['order_id', 'customer_id']], on='order_id')
q5_result = q5.groupby('customer_id').agg(
    order_count=('order_id', 'nunique'),
    total_clv=('order_value', 'sum'),
    avg_order_value=('order_value', 'mean')
).reset_index()
q5_result['total_clv'] = q5_result['total_clv'].round(2)
q5_result['avg_order_value'] = q5_result['avg_order_value'].round(2)
q5_result = q5_result.sort_values('total_clv', ascending=False).head(50)
q5_result.to_csv(f"{OUTPUT_DIR}/q5_customer_clv.csv", index=False)
print(q5_result.head(10).to_string(index=False))

print("\n── Q6: Average Review Score by Category ──")
# Join order_reviews with order_items to get product_id, then with products to get category
q6 = order_reviews_df.merge(order_items_df[['order_id', 'product_id']], on='order_id', how='left')
q6 = q6.merge(products_df[['product_id', 'product_category_name']], on='product_id', how='left')
q6 = q6.merge(category_trans_df, left_on='product_category_name', right_on='product_category_name', how='left')
q6_result = q6.groupby('product_category_name_english')['review_score'].agg(['mean', 'count']).reset_index()
q6_result.columns = ['category', 'avg_review_score', 'review_count']
q6_result['avg_review_score'] = q6_result['avg_review_score'].round(2)
q6_result = q6_result.sort_values('avg_review_score', ascending=False).dropna()
q6_result.to_csv(f"{OUTPUT_DIR}/q6_reviews_by_category.csv", index=False)
print(q6_result.head(15).to_string(index=False))

print("\n── Q7: High-Sales Products with Poor Ratings (<3.0) ──")
# Join order_items with order_reviews to get product ratings and sales
q7 = order_items_df.merge(order_reviews_df[['order_id', 'review_score']], on='order_id', how='left')
q7_result = q7.groupby('product_id').agg(
    units_sold=('order_item_id', 'count'),
    avg_review_score=('review_score', 'mean')
).reset_index()
q7_result = q7_result[q7_result['units_sold'] >= 10]
q7_result = q7_result[q7_result['avg_review_score'] < 3.0]
q7_result['avg_review_score'] = q7_result['avg_review_score'].round(2)
q7_result = q7_result.sort_values('units_sold', ascending=False)
q7_result.to_csv(f"{OUTPUT_DIR}/q7_high_sales_poor_rating.csv", index=False)
print(f"  Found {len(q7_result)} products with high sales but poor ratings")
print(q7_result.head(10).to_string(index=False) if len(q7_result) > 0 else "  None found")

print("\n── Q8: Monthly Order Trend ──")
orders_df['order_purchase_timestamp'] = pd.to_datetime(orders_df['order_purchase_timestamp'])
orders_df['year_month'] = orders_df['order_purchase_timestamp'].dt.to_period('M')
q8 = orders_df.merge(payments_df[['order_id', 'payment_value']], on='order_id')
q8_result = q8.groupby('year_month').agg(
    order_count=('order_id', 'nunique'),
    monthly_revenue=('payment_value', 'sum')
).reset_index()
q8_result['monthly_revenue'] = q8_result['monthly_revenue'].round(2)
q8_result['year_month'] = q8_result['year_month'].astype(str)
q8_result = q8_result.sort_values('year_month')
q8_result.to_csv(f"{OUTPUT_DIR}/q8_monthly_trend.csv", index=False)
print(q8_result.to_string(index=False))

print("\n── Q9: Delivery Time vs Review Score ──")
orders_df['order_purchase_timestamp'] = pd.to_datetime(orders_df['order_purchase_timestamp'])
orders_df['order_delivered_customer_timestamp'] = pd.to_datetime(orders_df['order_delivered_customer_date'])
orders_df['delivery_days'] = (orders_df['order_delivered_customer_timestamp'] - orders_df['order_purchase_timestamp']).dt.days
q9 = orders_df.merge(order_reviews_df[['order_id', 'review_score']], on='order_id', how='left')
q9_result = q9[q9['delivery_days'] >= 0].groupby('review_score')['delivery_days'].agg(['mean', 'count']).reset_index()
q9_result.columns = ['review_score', 'avg_delivery_days', 'order_count']
q9_result['avg_delivery_days'] = q9_result['avg_delivery_days'].round(1)
q9_result = q9_result.sort_values('review_score')
q9_result.to_csv(f"{OUTPUT_DIR}/q9_delivery_vs_score.csv", index=False)
print(q9_result.to_string(index=False))

print("\n── Q10: On-time vs Late Delivery Rate ──")
orders_df['order_estimated_delivery_timestamp'] = pd.to_datetime(orders_df['order_estimated_delivery_date'])
orders_df['on_time'] = orders_df['order_delivered_customer_timestamp'] <= orders_df['order_estimated_delivery_timestamp']
q10 = orders_df.merge(order_reviews_df[['order_id', 'review_score']], on='order_id', how='left')
q10_result = q10.groupby('on_time').agg(
    order_count=('order_id', 'count'),
    avg_review_score=('review_score', 'mean')
).reset_index()
q10_result['on_time'] = q10_result['on_time'].map({True: 'on_time', False: 'late'})
q10_result['avg_review_score'] = q10_result['avg_review_score'].round(2)
q10_result.to_csv(f"{OUTPUT_DIR}/q10_delivery_rate.csv", index=False)
print(q10_result.to_string(index=False))

print("\n── Q11: Top 20 Sellers by Revenue ──")
q11 = order_items_df.merge(sellers_df, on='seller_id', how='left')
q11 = q11.merge(order_reviews_df[['order_id', 'review_score']], on='order_id', how='left')
q11_result = q11.groupby('seller_id').agg(
    total_revenue=('price', 'sum'),
    total_freight=('freight_value', 'sum'),
    order_count=('order_id', 'nunique'),
    avg_review_score=('review_score', 'mean')
).reset_index()
q11_result['total_revenue'] = q11_result['total_revenue'].round(2)
q11_result['total_freight'] = q11_result['total_freight'].round(2)
q11_result['avg_review_score'] = q11_result['avg_review_score'].round(2)
q11_result = q11_result.sort_values('total_revenue', ascending=False).head(20)
q11_result.to_csv(f"{OUTPUT_DIR}/q11_seller_performance.csv", index=False)
print(q11_result.to_string(index=False))

print("\n── Q12: Review Score Distribution ──")
q12_result = order_reviews_df.groupby('review_score').agg(
    review_count=('review_id', 'count'),
    order_count=('order_id', 'nunique')
).reset_index()
q12_result['review_count'] = q12_result['review_count'].astype(int)
q12_result = q12_result.sort_values('review_score')
q12_result.to_csv(f"{OUTPUT_DIR}/q12_review_distribution.csv", index=False)
print(q12_result.to_string(index=False))

print("\n── Q13: Revenue by Customer State ──")
q13 = orders_df.merge(customers_df[['customer_id', 'customer_state']], on='customer_id', how='left')
q13 = q13.merge(payments_df[['order_id', 'payment_value']], on='order_id', how='left')
q13_result = q13.groupby('customer_state').agg(
    order_count=('order_id', 'nunique'),
    total_revenue=('payment_value', 'sum'),
    avg_order_value=('payment_value', 'mean')
).reset_index()
q13_result['total_revenue'] = q13_result['total_revenue'].round(2)
q13_result['avg_order_value'] = q13_result['avg_order_value'].round(2)
q13_result = q13_result.sort_values('total_revenue', ascending=False)
q13_result.to_csv(f"{OUTPUT_DIR}/q13_state_heatmap.csv", index=False)
print(q13_result.to_string(index=False))

print("\n" + "=" * 70)
print(" Python Analytics complete!")
print(f" Results saved to: {OUTPUT_DIR}")
print("=" * 70)
