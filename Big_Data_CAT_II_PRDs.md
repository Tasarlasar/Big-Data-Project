# Big Data Computing Laboratory – CAT II
# Product Requirements Document (PRD)

## Project 1: Multi-Source E-Commerce Big Data Processing and Analytics

### 1. Project Overview
Build an end-to-end Big Data pipeline integrating structured e-commerce transaction data with large-scale Amazon product and review data. The system demonstrates distributed storage, SQL-to-HDFS ingestion, NoSQL storage, batch processing, and structured analytics using HDFS, MongoDB, Apache PIG, and Apache HIVE.

### 2. Problem Statement
E-commerce systems generate data in multiple formats and at different scales. Transactional data is structured, while product metadata and customer reviews can be semi-structured or unstructured. The project builds a Hadoop-based pipeline for ingesting, storing, transforming, and analysing heterogeneous e-commerce data.

### 3. Objectives
- Import structured relational data into HDFS.
- Import large-scale external/JSON data into HDFS.
- Demonstrate structured, semi-structured, and unstructured data handling.
- Store flexible document data using MongoDB.
- Use Apache PIG for transformation, filtering, joining, grouping, and aggregation.
- Use Apache HIVE for structured analytical queries.
- Produce meaningful e-commerce insights.

### 4. Data Sources

#### 4.1 Olist Brazilian E-Commerce Dataset
Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

Approximate scale: 100,000 orders.

Important files:
- customers.csv
- orders.csv
- order_items.csv
- order_payments.csv
- order_reviews.csv
- products.csv
- sellers.csv
- geolocation.csv
- product_category_name_translation.csv

Purpose:
- Structured data
- Relational database / SQL source
- SQL → HDFS using Sqoop
- Hive analytics

#### 4.2 Amazon Reviews'23
Source: https://amazon-reviews-2023.github.io/

The full dataset contains hundreds of millions of reviews. For laboratory implementation, a manageable category-level subset will be selected; Automotive is a proposed starting category because it contains roughly 20 million reviews.

Data includes ratings, review titles, review text, helpful votes, timestamps, verified purchase information, product metadata, categories, prices, images, videos, and related products.

Purpose:
- Large-scale Big Data source
- JSON/JSONL semi-structured data
- Free-form review text
- Product media
- MongoDB and PIG processing

### 5. Data Classification

| Data | Type | Main Technology |
|---|---|---|
| Olist customers/orders/products | Structured | MySQL, HDFS, Hive |
| Olist payments/order items | Structured | MySQL, HDFS, Hive |
| Amazon review JSONL | Semi-structured | HDFS, MongoDB, PIG |
| Amazon product metadata | Semi-structured | HDFS, MongoDB, PIG |
| Review text | Unstructured text | HDFS, PIG |
| Product images/videos | Unstructured media | HDFS |

### 6. Functional Requirements

#### FR1 – Data Ingestion
The system shall ingest Olist relational data and Amazon JSON/JSONL data.

#### FR2 – SQL to HDFS
The system shall load Olist data into MySQL, create relational tables, and import selected tables into HDFS using Sqoop or an equivalent SQL-to-HDFS mechanism.

#### FR3 – External/Unstructured Data to HDFS
The system shall store Amazon JSONL data and selected product media in HDFS.

#### FR4 – HDFS Organization
Create separate HDFS directories for raw structured data, raw semi-structured data, unstructured data, processed data, and analytical outputs.

#### FR5 – MongoDB
Store selected Amazon product/review documents in MongoDB and demonstrate document queries and aggregation.

#### FR6 – PIG Processing
PIG shall perform LOAD, FILTER, JOIN, GROUP, FOREACH, ORDER, DISTINCT, and STORE operations where appropriate.

Example processing:
- Filter invalid review records.
- Group reviews by product/category.
- Calculate review counts and average ratings.
- Join relevant Olist datasets.
- Generate processed analytical datasets.

#### FR7 – HIVE Analytics
Hive tables shall be created for structured Olist and processed datasets.

Example analyses:
- Total sales/revenue.
- Revenue by product category.
- Top-selling products.
- Customer purchase value.
- Payment method distribution.
- Average rating by category.
- Products with high sales but poor ratings.
- Review volume by category.
- Delivery time versus review score.

### 7. Proposed Architecture

```text
Olist CSV → MySQL → Sqoop ───────┐
                                 │
Amazon JSONL / Metadata ─────────┤
                                 ↓
                                HDFS
                                 │
                ┌────────────────┼────────────────┐
                ↓                ↓                ↓
             MongoDB            PIG              HIVE
                │                │                │
         Document queries   Transformations   Analytics
                │                │                │
                └────────────────┴────────────────┘
                                 ↓
                         E-Commerce Insights
```

### 8. Expected Deliverables
- Dataset documentation
- HDFS directory structure
- MySQL schema
- SQL-to-HDFS/Sqoop commands
- MongoDB database and collections
- PIG scripts
- Hive tables and queries
- Output datasets
- Architecture diagram
- Final report
- Demonstration/viva documentation

---

# Project 2: Tokyo Railway and Public Transport Big Data Analytics

## 1. Project Overview
Build a Big Data processing and analytics pipeline for the Greater Tokyo railway and public transportation network. The project will integrate railway GTFS datasets from multiple Japanese operators and complementary transport data, store them in HDFS, process them using MongoDB and Apache PIG, and perform structured analytics using Apache HIVE.

## 2. Problem Statement
Tokyo's public transportation network consists of many railway operators, routes, stations, trips, and schedules. Data is distributed across different operators and sources. Integrating and processing this information provides a realistic use case for Hadoop-based distributed processing.

## 3. Objectives
- Collect publicly available Tokyo-area railway/public transport datasets.
- Integrate data from multiple railway operators.
- Store raw transportation data in HDFS.
- Demonstrate structured and semi-structured data processing.
- Use MongoDB for flexible transportation documents.
- Use PIG for cleaning, joining, transforming, and aggregating transport data.
- Use HIVE for structured railway analytics.
- Generate insights about routes, stations, schedules, and operators.

## 4. Data Sources

### 4.1 TrainGTFSGenerator
Source: https://github.com/fksms/TrainGTFSGenerator

The repository generates GTFS data for Japanese railway operators and includes 22 operators, including JR East, Tokyo Metro, Toei, Keio, Tokyu, Seibu, Tobu, Odakyu, Keikyu, Keisei, Yurikamome, Tokyo Monorail, Tsukuba Express, and others.

Generated GTFS data is available through the repository's releases.

### 4.2 TokyoGTFS
Source: https://github.com/MKuranowski/TokyoGTFS

Provides GTFS data for Tokyo-area railway and bus transportation.

### 4.3 Tokyo Open Data
Source: https://catalog.data.metro.tokyo.lg.jp/

The Tokyo Open Data catalogue contains public transportation datasets, including GTFS and other formats. Availability and access requirements should be checked for each selected feed before implementation.

## 5. Data Classification

| Data | Type | Main Technology |
|---|---|---|
| stops | Structured | HDFS, Hive |
| routes | Structured | HDFS, Hive |
| trips | Structured | HDFS, Hive |
| stop_times | Structured | HDFS, PIG, Hive |
| calendar/calendar_dates | Structured | HDFS, Hive |
| Transport JSON | Semi-structured | HDFS, MongoDB, PIG |
| Operator/source metadata | Semi-structured | MongoDB, PIG |

Unstructured media is not required in this project because Project 1 demonstrates it.

## 6. Functional Requirements

### FR1 – Data Collection
Collect GTFS datasets from multiple Tokyo-area railway operators.

### FR2 – HDFS Ingestion
Store raw GTFS and complementary transport data in HDFS.

### FR3 – Multi-Source Integration
Combine relevant datasets from multiple operators and sources.

### FR4 – MongoDB
Store selected transport records as documents.

Example:
```json
{
  "operator": "Tokyo Metro",
  "route": "Ginza Line",
  "station": "Shibuya",
  "service_type": "rail"
}
```

### FR5 – PIG Processing
PIG shall perform LOAD, FILTER, JOIN, GROUP, FOREACH, ORDER, DISTINCT, and STORE operations where appropriate.

Example processing:
- Remove duplicate station records.
- Normalize operator names.
- Join routes, trips, stops, and stop_times.
- Calculate scheduled journey duration.
- Count trips per route.
- Count services per station.
- Aggregate routes by operator.

### FR6 – HIVE Analytics
Hive shall perform structured analysis such as:
- Number of stations per operator.
- Number of routes per operator.
- Number of trips per route.
- Stations served by multiple routes.
- Most connected stations.
- Scheduled services by hour.
- Average scheduled journey duration.
- Routes with the highest number of stops.
- Operator-level network comparison.

## 7. Proposed Architecture

```text
TrainGTFSGenerator ──────┐
                         │
TokyoGTFS ───────────────┤
                         │
Tokyo Open Data ─────────┘
                         ↓
                        HDFS
                         │
             ┌───────────┼───────────┐
             ↓           ↓           ↓
          MongoDB       PIG         HIVE
             │           │           │
        Transport     Clean +      Structured
        documents     Join +       Analytics
                      Transform
             │           │           │
             └───────────┴───────────┘
                         ↓
                Tokyo Transport Insights
```

## 8. Important Processing Principle
GTFS is already a standardized format, so the project should not claim that all raw data is highly unclean. The main PIG contribution is multi-source integration, transformation, joins, aggregation, normalization, validation, and derived-field generation.

## 9. Expected Deliverables
- Dataset/source documentation
- HDFS directory structure
- MongoDB collections
- PIG scripts
- Hive tables
- Hive analytical queries
- Processed datasets
- Architecture diagram
- Final report
- Demonstration/viva documentation

---

# CAT-II Requirement Coverage

| CAT-II Requirement | E-Commerce | Tokyo Railway |
|---|---|---|
| External/unstructured data → HDFS | Amazon JSONL/media → HDFS | GTFS/transport data → HDFS |
| SQL → HDFS | Olist → MySQL → Sqoop → HDFS | Not primary |
| NoSQL storage/processing | MongoDB | MongoDB |
| PIG processing | Olist + Amazon reviews/metadata | GTFS integration/transformation |
| HIVE processing/analysis | Sales, orders, products, customers, reviews | Routes, stations, trips, schedules |
| Structured data | Olist | GTFS |
| Semi-structured data | Amazon JSON/JSONL | Transport JSON |
| Unstructured data | Review text + selected product images/videos | Not required |
| Large-scale data | Amazon category-level dataset | Multiple railway operators |

# Overall Technology Stack

- HDFS – Distributed storage
- MySQL – Relational source database
- Sqoop – SQL-to-HDFS ingestion where supported
- MongoDB – NoSQL/document storage
- Apache PIG – Batch processing and transformation
- Apache HIVE – Structured querying and analytics
- Python/Bash – Optional preparation and automation
- Git/GitHub – Version control

# Success Criteria

The projects are complete when the team can demonstrate:
1. Data imported into HDFS from an external source.
2. Relational SQL data transferred into HDFS.
3. Data stored and queried in MongoDB.
4. PIG scripts performing meaningful transformations.
5. Hive tables created from processed structured data.
6. Hive queries producing meaningful analytical results.
7. Structured, semi-structured, and unstructured data demonstrated across the two projects.
8. An end-to-end flow from raw source to analytical output.
