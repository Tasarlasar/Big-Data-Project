# E-Commerce Big Data Pipeline - Completion Report

## Date: 2026-10-12

---

## Status of Each Pipeline Step

| Step | Description | Status |
|------|-------------|--------|
| 1 | HDFS Setup | COMPLETE |
| 2 | MySQL (Sqoop equivalent) | COMPLETE - Data imported to /user/bigdata/ecommerce/sqoop_import/ |
| 3 | PIG Processing (Step 6) | COMPLETE - 6 output directories created in /user/bigdata/ecommerce/processed/ |
| 4 | Hive/Spark SQL | SKIPPED - Replaced with Python analytics (Step 8) |
| 5 | MongoDB | SKIPPED (--skip-mongo flag) |
| 6 | Analytics | COMPLETE - All 13 queries executed |

---

## Errors Encountered and Fixes

### 1. Hive-on-MR Compatibility Issue
- **Issue**: Hive on MapReduce has known compatibility issues on macOS (Apple Silicon)
- **Fix**: Replaced Hive with Python/pandas analytics in 07_hive/05_python_analytics.py
- **Status**: Resolved - analytics now run successfully with pandas

### 2. Amazon Data Download
- **Issue**: Data download step was failing
- **Fix**: Skip download step via --skip-download flag
- **Status**: Resolved - using pre-loaded HDFS data

### 3. reviews_filtered Field Count Issue
- **Issue**: Q6-Q13 queries were skipped due to field count issues in PIG output
- **Fix**: Implemented all 8 queries (Q6-Q13) directly using raw HDFS DataFrames (orders_df, order_items_df, payments_df, products_df, customers_df, sellers_df, category_trans_df, order_reviews_df)
- **Status**: Resolved - all queries now execute successfully

### 4. PIG Processing Timeouts
- **Issue**: PIG scripts running on YARN were taking extended time due to small cluster configuration
- **Fix**: Allowed scripts to complete - all 5 PIG scripts finished successfully
- **Status**: Resolved - completed after ~35 minutes of execution

---

## Output Files Created

### Python Analytics Outputs (/08_run/python_outputs/)

| File | Description | Rows (excluding header) |
|------|-------------|------------------------|
| q1_total_orders_revenue.csv | Total orders, revenue, avg order value | 1 |
| q2_revenue_by_category.csv | Revenue by category (top 15) | 15 |
| q3_top_products_revenue.csv | Top 50 products by revenue | 50 |
| q4_payment_methods.csv | Payment method distribution | 5 |
| q5_customer_clv.csv | Customer lifetime value (top 50) | 50 |
| q6_reviews_by_category.csv | Average review score by category | 71 |
| q7_high_sales_poor_rating.csv | High-sales products with poor ratings | 90 |
| q8_monthly_trend.csv | Monthly order trend with revenue | 25 |
| q9_delivery_vs_score.csv | Delivery time vs review score | 5 |
| q10_delivery_rate.csv | On-time vs late delivery rate | 2 |
| q11_seller_performance.csv | Top 20 sellers by revenue | 20 |
| q12_review_distribution.csv | Review score distribution | 5 |
| q13_state_heatmap.csv | Revenue by customer state | 27 |

### PIG Processing Outputs (HDFS)

| Directory | Description |
|-----------|-------------|
| /user/bigdata/ecommerce/processed/orders_joined | Orders joined with items and payments |
| /user/bigdata/ecommerce/processed/revenue_by_category | Revenue aggregated by category |
| /user/bigdata/ecommerce/processed/reviews_by_category | Reviews aggregated by category |
| /user/bigdata/ecommerce/processed/reviews_by_product | Reviews aggregated by product |
| /user/bigdata/ecommerce/processed/reviews_filtered | Filtered reviews dataset |
| /user/bigdata/ecommerce/processed/top_products | Top products by sales |

### Sqoop Import (HDFS)

| Table | Location |
|-------|----------|
| category_translation | /user/bigdata/ecommerce/sqoop_import/category_translation |
| customers | /user/bigdata/ecommerce/sqoop_import/customers |
| geolocation | /user/bigdata/ecommerce/sqoop_import/geolocation |
| order_items | /user/bigdata/ecommerce/sqoop_import/order_items |
| order_payments | /user/bigdata/ecommerce/sqoop_import/order_payments |
| order_reviews | /user/bigdata/ecommerce/sqoop_import/order_reviews |
| orders | /user/bigdata/ecommerce/sqoop_import/orders |
| products | /user/bigdata/ecommerce/sqoop_import/products |
| sellers | /user/bigdata/ecommerce/sqoop_import/sellers |

---

## Key Results Summary

### Top Revenue Categories (Q2)
1. health_beauty - R$1,258,681.34
2. watches_gifts - R$1,205,005.68
3. bed_bath_table - R$1,036,988.68
4. sports_leisure - R$988,048.97
5. computers_accessories - R$911,954.32

### Payment Methods (Q4)
- Credit card: 76,505 orders (R$12.5M)
- Boleto: 19,784 orders (R$2.9M)
- Voucher: 3,866 orders (R$379K)
- Debit card: 1,528 orders (R$218K)

### Delivery Performance (Q10)
- On-time: 89,139 orders (4.29 avg review score)
- Late: 10,853 orders (2.35 avg review score)

### Top Customer States by Revenue (Q13)
1. SP ( Sao Paulo ) - R$5.9M
2. RJ (Rio de Janeiro) - R$2.1M
3. MG (Minas Gerais) - R$1.8M

---

## Remaining Issues

1. **Hadoop Native Library Warning**: "Unable to load native-hadoop library for your platform" - cosmetic warning, does not affect functionality
2. **PIG MapReduce Mode**: PIG runs in MapReduce mode which is slower on macOS - considered acceptable for this environment
3. **No Hive Installation**: Hive is not installed on this system - mitigated by Python analytics replacement

---

## Pipeline Execution Summary

- **Total Runtime**: ~45 minutes (PIG: ~35 min, Python analytics: ~10 min)
- **Data Processed**: 100K orders, 112K order items, 103K payments, 33K products, 99K customers, 3K sellers
- **Output Files**: 13 CSV files in 08_run/python_outputs/
- **HDFS Storage**: All raw and processed data retained

---

## Technical Environment

- **OS**: macOS (Apple Silicon)
- **Java**: OpenJDK 17
- **Hadoop**: Homebrew installed
- **Pig**: Homebrew installed (0.18.0)
- **Python**: 3.14 with pandas
- **MySQL**: Homebrew installed (password: 'password')

---

Report Generated: 2026-10-12 04:31 UTC
