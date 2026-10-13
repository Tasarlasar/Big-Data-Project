# Big Data Computing CAT II
## Multi-Source Big Data Processing and Analytics Pipeline

This repository contains two complete big data projects demonstrating Hadoop-based processing of heterogeneous data:

---

## 🚀 Quick Start

### Run the E-Commerce Pipeline
```bash
cd /path/to/E-commerce
export MYSQL_PASS=password
bash 08_run/run_pipeline.sh
```

### Run the Tokyo Railway Pipeline
```bash
cd /path/to/E-commerce
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
bash 14_tokyo_run/run_pipeline.sh
```

### Run Local Analytics (Hadoop-free)
```bash
python3 08_run/local_analytics.py --archive ./archive
```

---

## 📊 Project 1: Multi-Source E-Commerce Big Data Processing

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DATA SOURCES                                       │
│  ┌─────────────────────┐         ┌───────────────────────────────────┐      │
│  │  Olist Brazilian    │         │    Amazon Reviews'23              │      │
│  │  Brazilian E-Commerce│        │    Automotive Category            │      │
│  │  (CSV, Relational)  │         │    (JSONL, Semi-structured)       │      │
│  └──────────┬──────────┘         └────────────────────┬──────────────┘      │
│             │                                         │                      │
└─────────────┼─────────────────────────────────────────┼──────────────────────┘
              │                                         │
              ▼                                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          HDFS LAYER                                         │
│  ┌──────────────────┬──────────────────────┬──────────────────────────┐    │
│  │  raw/structured  │ raw/semi_structured  │   processed/             │    │
│  │  (Olist CSVs)    │ (Amazon JSONL)       │   - reviews_filtered     │    │
│  └──────────────────┴──────────────────────┴─── - orders_joined       │    │
│                                                  - revenue_by_category │    │
│                                                  - top_products        │    │
└─────────────────────────────────────────────────────────────────────────────┘
              │                       │                       │
              ▼                       ▼                       ▼
┌────────────────── ┐      ┌──────────────────┐      ┌───────────────────────┐
│    MongoDB        │      │   Apache PIG     │      │   Apache HIVE         │
│  - amazon_reviews │◄────►│  - Transform     │◄────►│  - External Tables    │
│  - amazon_products│      │  - Filter        │      │  - 13 Analytics       │
│  - enriched docs  │      │  - Join/Group    │      │  - ORC Outputs        │
└────────────────── ┘      │  - Aggregate     │      └───────────────────────┘
                           └──────────────────┘
```

### Repository Structure

```
E-commerce/
├── archive/                      Raw Olist CSV files (source data)
│   ├── olist_customers_dataset.csv
│   ├── olist_orders_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_products_dataset.csv
│   ├── olist_sellers_dataset.csv
│   ├── olist_geolocation_dataset.csv
│   └── product_category_name_translation.csv
│
├── 01_mysql/                     MySQL schema + data load scripts
│   ├── 01_create_schema.sql      DDL for all 9 Olist tables
│   ├── 02_load_data.sql          LOAD DATA INFILE for all tables
│   └── 03_verify_schema.sql      Row-count and sanity checks
│
├── 02_hdfs/                      HDFS directory setup
│   ├── 01_hdfs_setup.sh          Creates full HDFS tree
│   └── 02_upload_csvs_to_hdfs.sh Direct CSV → HDFS upload (Sqoop fallback)
│
├── 03_sqoop/                     SQL → HDFS ingestion
│   ├── 01_sqoop_import.sh        Imports all MySQL tables via Sqoop
│   ├── 02_sqoop_verify.sh        Compares MySQL vs HDFS row counts
│   ├── 03_sqoop_equivalent.py    Python equivalent (Sqoop 1.4.7 incompatible with Hadoop 3.x)
│   └── README_SQOOP_NOTE.md      Sqoop compatibility note
│
├── 04_amazon_hdfs/               Amazon data download + HDFS staging
│   ├── 01_download_amazon_data.sh  Downloads Automotive JSONL (or sample)
│   └── 02_sample_amazon_data.py   Reservoir-samples large JSONL files
│
├── 05_mongodb/                   MongoDB collections + queries
│   ├── 01_setup_collections.js   Creates collections with schema validation
│   ├── 02_import_amazon_reviews.sh  Bulk import via mongoimport
│   ├── 03_import_amazon_metadata.sh Bulk import product metadata
│   ├── 04_build_olist_enriched.py   Denormalized order documents (Python)
│   └── 05_mongodb_queries.js     Aggregation pipeline queries
│
├── 06_pig/                       Apache PIG transformation scripts
│   ├── 01_filter_amazon_reviews.pig   FILTER + DISTINCT invalid reviews
│   ├── 02_reviews_by_product.pig      GROUP + aggregate by ASIN
│   ├── 03_join_olist_orders.pig       JOIN orders/items/products/payments
│   ├── 04_revenue_by_category.pig     Revenue aggregation by category
│   ├── 05_top_products.pig            Top products by revenue/units
│   └── 06_run_pig_scripts.sh          Runs all PIG scripts in order
│
├── 07_hive/                      Apache Hive tables + analytics
│   ├── 01_create_tables.hql      External table DDL (Olist + Amazon)
│   ├── 02_analytics_queries.hql  13 analytical queries
│   └── 03_save_hive_outputs.hql  Persist results as ORC tables
│
├── 08_run/
│   ├── local_analytics.py        Standalone Python analytics (no Hadoop needed)
│   └── run_pipeline.sh           Master end-to-end runner
│
└── staging/                      Staging directory for Amazon data
    ├── amazon/reviews/Automotive.jsonl
    └── amazon/metadata/meta_Automotive.jsonl
```

### Technology Stack

| Tool | Version | Purpose |
|------|---------|---------|
| Hadoop / HDFS | 3.x | Distributed storage |
| MySQL | 8.0 | Relational source database |
| Sqoop | 1.4.7 (via Python equivalent) | SQL → HDFS ingestion |
| MongoDB | 6.0 | NoSQL/document storage |
| Apache PIG | 0.17 | Batch processing & transformation |
| Apache Hive | 3.x | Structured querying & analytics |
| Python | 3.10+ | Data preparation & automation |
| pymongo | 4.x | MongoDB operations |

### Data Sources

- **Olist Brazilian E-Commerce**: [kaggle.com/datasets/olistbr/brazilian-ecommerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
  - ~100,000 orders, 9 relational tables
- **Amazon Reviews'23**: [amazon-reviews-2023.github.io](https://amazon-reviews-2023.github.io/)
  - Automotive category: ~20M reviews (full) / 500K (sample)

### Hive Analytical Queries

| # | Query | Insight |
|---|-------|---------|
| Q1 | Total orders, revenue, avg order value | Overall business KPIs |
| Q2 | Revenue by product category | Top-earning categories |
| Q3 | Top 20 best-selling products | Product performance |
| Q4 | Payment method distribution | Customer payment preferences |
| Q5 | Customer lifetime value (top 20) | High-value customer identification |
| Q6 | Review score by category | Quality per category |
| Q7 | High-sales / poor-rating products | Product quality issues |
| Q8 | Monthly order trend | Seasonality and growth |
| Q9 | Delivery time vs review score | Logistics impact on satisfaction |
| Q10 | On-time vs late delivery rate | Fulfilment reliability |
| Q11 | Top 20 sellers by revenue | Seller performance |
| Q12 | Amazon verified vs unverified ratings | Review authenticity analysis |
| Q13 | State-level sales heatmap | Regional demand patterns |

---

## 🚆 Project 2: Tokyo Railway and Public Transport Big Data Analytics

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DATA SOURCES                                       │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌──────────────────┐     │
│  │  TrainGTFSGenerator │  │   TokyoGTFS         │  │  Tokyo Open Data │     │
│  │  (20 operators)     │  │   (GTFS)            │  │  (GTFS-JP)       │     │
│  └──────────┬──────────┘  └──────────┬──────────┘  └──────────┬───────┘     │
│             │                         │                        │            │
└─────────────┼─────────────────────────┼────────────────────────┼────────────┘
              │                         │                        │
              ▼                         ▼                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          HDFS LAYER                                         │
│  ┌──────────────────┬──────────────────────┬──────────────────────────┐     │
│  │  raw/gtfs/       │ raw/semi_structured  │   processed/             │     │
│  │  - jr_east       │ (operator_metadata)  │   - aggregated_routes    │     │
│  │  - tokyo_metro   │                        │   - station_network    │     │
│  │  - toei          │                        │                        │     │
│  │  - private_rail  │                        │                        │     │
│  └──────────────────┴──────────────────────┴──────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────┘
              │                       │                       │
              ▼                       ▼                       ▼
┌──────────────────┐      ┌──────────────────┐     ┌───────────────────────┐
│    MongoDB       │      │   Apache PIG     │     │   Apache HIVE         │
│  - operators     │◄────►│  - Load GTFS     │◄────►│  - External Tables   │
│  - routes        │      │  - Normalize     │     │  - 15 Analytics       │
│  - stations      │      │  - Join          │     │  - ORC Outputs        │
│  - trips         │      │  - Aggregate     │     └───────────────────────┘
│  - schedules     │      │  - Analyze       │
│  - network_stats │      └──────────────────┘
└──────────────────┘
```

### Repository Structure

```
E-commerce/
├── 09_tokyo_gtfsgenerator/       Tokyo GTFS data from TrainGTFSGenerator
│   └── raw/                      20 operators (20+ MB)
│       ├── agency.txt
│       ├── calendar.txt
│       ├── calendar_dates.txt
│       ├── feed_info.txt
│       ├── routes.txt
│       ├── stop_times.txt
│       ├── stops.txt
│       ├── translations.txt
│       └── trips.txt
│
├── 10_tokyo_hdfs/                HDFS directory setup
│   ├── 01_hdfs_setup.sh          Creates HDFS tree
│   └── 02_upload_to_hdfs.sh      Uploads GTFS to HDFS
│
├── 11_tokyo_mongodb/             MongoDB collections
│   └── 01_setup_collections.js   Sets up tokyo_transport database
│
├── 12_tokyo_pig/                 Apache PIG scripts
│   ├── 01_load_gtfs.pig          Load and clean GTFS files
│   ├── 02_normalize_operators.pig Normalize operator names
│   ├── 03_join_gtfs.pig          Join routes↔trips↔stops↔stop_times
│   ├── 04_aggregate_routes.pig   Aggregate trips/stops per route
│   ├── 05_analyze_network.pig    Analyze station connectivity
│   └── 06_run_pig_scripts.sh     Runs all PIG scripts
│
├── 13_tokyo_hive/                Apache Hive
│   ├── 01_create_tables.hql      External table DDL
│   ├── 02_analytics_queries.hql  15 analytical queries
│   └── 03_save_outputs.hql       ORC output tables
│
└── 14_tokyo_run/                 Pipeline runner
    ├── run_pipeline.sh           Master orchestrator
    └── README.md                 Tokyo-specific documentation
```

### Operators Included (20 total)

**JR Group:**
- JR-East-Train (East Japan Railway)

**Private Railways:**
- Keio-Train, Keisei-Train, Odakyu-Train, Seibu-Train, Tobu-Train, Tokyu-Train, Sotetsu-Train, ShinKeisei-Train

**Subways:**
- TokyoMetro-Train, Toei-Train, Yurikamome-Train

**Monorails:**
- TokyoMonorail-Train, TamaMonorail-Train

**Other:**
- Hokuso-Train, MIR-Train, Minatomirai-Train, SR-Train, TWR-Train (Tokyo Waterfront Area Rapid Transit)

### Hive Analytical Queries

| # | Query | Insight |
|---|-------|---------|
| Q1 | Stations per operator | Network coverage by operator |
| Q2 | Routes per operator | Route distribution |
| Q3 | Trips per route | Service frequency |
| Q4 | Stops per route | Route length |
| Q5 | Top 20 most connected stations | Network hubs |
| Q6 | Hourly service distribution | Peak hours analysis |
| Q7 | Routes with most stops | Longest routes |
| Q8 | Operator-level network comparison | Cross-operator analysis |
| Q9 | Most frequent operators | Service volume |
| Q10 | Routes serving multiple operators | Interoperability |
| Q11 | Top 10 busiest stations | Station traffic |
| Q12 | Service by day type | Weekday vs weekend |
| Q13 | Routes with highest frequency | High-capacity routes |
| Q14 | Operator route type distribution | Service mix |
| Q15 | 7-day route identification | Continuous service routes |

---

## 📁 Prerequisites

| Tool | Minimum Version | Notes |
|------|-----------------|-------|
| Hadoop / HDFS | 3.x | Running cluster |
| MySQL | 8.0 | For Olist data (E-commerce) |
| MongoDB | 6.0 | For both projects |
| Apache PIG | 0.17 | Batch processing |
| Apache Hive | 3.x | Structured queries |
| Python | 3.10+ | Data preparation |
| Java (JDK) | 11 or 17 | Required by Hadoop, Hive, PIG |
| Git Bash / WSL2 | — | Needed to run `.sh` scripts on Windows |

---

## 🪟 Windows Agent Setup Guide

> This section is written for an automated agent taking over the project on a Windows machine.  Follow every step in order.

### 0. Prerequisites — install these first

```powershell
# Install Chocolatey (run in an elevated PowerShell)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install core tools via Chocolatey
choco install -y git            # includes Git Bash
choco install -y python311      # Python 3.11
choco install -y temurin17      # Eclipse Temurin JDK 17 (Adoptium)
choco install -y mysql          # MySQL 8.0
choco install -y mongodb        # MongoDB 6.x Community Edition
```

After installation, confirm Java is on the PATH:

```powershell
java -version   # should print 17.x
```

Set JAVA_HOME permanently (replace the path if Temurin installed elsewhere):

```powershell
[System.Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Eclipse Adoptium\jdk-17.0.x.x-hotspot', 'Machine')
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.x.x-hotspot'
```

### 1. Install Hadoop 3.x on Windows

Hadoop does not ship a native Windows installer.  Use the prebuilt winutils bundle:

```powershell
# 1. Download Hadoop 3.3.6 binary (Apache mirror)
$hadoopUrl = 'https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz'
Invoke-WebRequest -Uri $hadoopUrl -OutFile C:\hadoop-3.3.6.tar.gz

# 2. Extract (requires 7-Zip or tar on Windows 10+)
tar -xf C:\hadoop-3.3.6.tar.gz -C C:\

# 3. Download winutils.exe for Hadoop 3.3 (community build)
#    Source: https://github.com/cdarlint/winutils
$winutilsBase = 'https://github.com/cdarlint/winutils/raw/master/hadoop-3.3.5/bin'
$hadoopBin    = 'C:\hadoop-3.3.6\bin'
Invoke-WebRequest -Uri "$winutilsBase/winutils.exe"  -OutFile "$hadoopBin\winutils.exe"
Invoke-WebRequest -Uri "$winutilsBase/hadoop.dll"   -OutFile "$hadoopBin\hadoop.dll"

# 4. Set environment variables
[System.Environment]::SetEnvironmentVariable('HADOOP_HOME', 'C:\hadoop-3.3.6', 'Machine')
[System.Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\hadoop-3.3.6\bin', 'Machine')
$env:HADOOP_HOME = 'C:\hadoop-3.3.6'
```

Configure pseudo-distributed mode by editing these XML files inside `%HADOOP_HOME%\etc\hadoop\`:

**core-site.xml**
```xml
<configuration>
  <property><name>fs.defaultFS</name><value>hdfs://localhost:9000</value></property>
  <property><name>hadoop.proxyuser.Administrator.hosts</name><value>*</value></property>
  <property><name>hadoop.proxyuser.Administrator.groups</name><value>*</value></property>
</configuration>
```

**hdfs-site.xml**
```xml
<configuration>
  <property><name>dfs.replication</name><value>1</value></property>
  <property><name>dfs.namenode.name.dir</name><value>C:/hadoop/data/namenode</value></property>
  <property><name>dfs.datanode.data.dir</name><value>C:/hadoop/data/datanode</value></property>
</configuration>
```

**mapred-site.xml**
```xml
<configuration>
  <property><name>mapreduce.framework.name</name><value>yarn</value></property>
</configuration>
```

**yarn-site.xml**
```xml
<configuration>
  <property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property>
</configuration>
```

Format the namenode (first time only) and start the cluster:

```powershell
hdfs namenode -format
start-dfs.cmd
start-yarn.cmd
# Verify: http://localhost:9870 (NameNode UI)
```

### 2. Install Apache PIG 0.18 on Windows

```powershell
$pigUrl = 'https://downloads.apache.org/pig/pig-0.18.0/pig-0.18.0.tar.gz'
Invoke-WebRequest -Uri $pigUrl -OutFile C:\pig-0.18.0.tar.gz
tar -xf C:\pig-0.18.0.tar.gz -C C:\
[System.Environment]::SetEnvironmentVariable('PIG_HOME', 'C:\pig-0.18.0', 'Machine')
[System.Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\pig-0.18.0\bin', 'Machine')
$env:PIG_HOME = 'C:\pig-0.18.0'
```

Copy the Hadoop runtime JAR so PIG can find it:

```powershell
$src = "$env:HADOOP_HOME\share\hadoop\common\lib"
$dst = "$env:PIG_HOME\lib"
Copy-Item "$src\commons-collections-3.2.2.jar" -Destination $dst -Force
```

Verify: `pig -version` in Git Bash.

### 3. Install Apache Hive 3.x on Windows

```powershell
$hiveUrl = 'https://downloads.apache.org/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz'
Invoke-WebRequest -Uri $hiveUrl -OutFile C:\apache-hive-3.1.3-bin.tar.gz
tar -xf C:\apache-hive-3.1.3-bin.tar.gz -C C:\
[System.Environment]::SetEnvironmentVariable('HIVE_HOME', 'C:\apache-hive-3.1.3-bin', 'Machine')
[System.Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\apache-hive-3.1.3-bin\bin', 'Machine')
$env:HIVE_HOME = 'C:\apache-hive-3.1.3-bin'
```

Initialise the Hive metastore (Derby, embedded):

```powershell
schematool -initSchema -dbType derby
```

### 4. Install Python dependencies

```powershell
pip install -r requirements.txt
```

The `requirements.txt` in the repo root lists every Python package needed (pymongo, pandas, plotly, dash, etc.).

### 5. Download large data files (not in the repo)

These files exceed GitHub's 100 MB limit and are excluded via `.gitignore`.  Download them manually before running any pipeline.

#### 5a. Olist Brazilian E-Commerce (Kaggle)

```powershell
# Install Kaggle CLI
pip install kaggle

# Place your kaggle.json API token at %USERPROFILE%\.kaggle\kaggle.json
# Download dataset
kaggle datasets download -d olistbr/brazilian-ecommerce -p .\archive --unzip
```

Expected files in `archive\`:
- `olist_customers_dataset.csv`
- `olist_orders_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_payments_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_products_dataset.csv`
- `olist_sellers_dataset.csv`
- `olist_geolocation_dataset.csv`
- `product_category_name_translation.csv`

#### 5b. Amazon Reviews 2023 — Automotive

```powershell
# Reviews (~500 MB sample):
Invoke-WebRequest -Uri 'https://datarepo.eng.ucsd.edu/mcauley_group/data/amazon_2023/raw/review_categories/Automotive.jsonl.gz' -OutFile staging\amazon\reviews\Automotive.jsonl.gz

# Decompress:
$gzPath  = 'staging\amazon\reviews\Automotive.jsonl.gz'
$outPath = 'staging\amazon\reviews\Automotive.jsonl'
$stream  = [System.IO.Compression.GzipStream]::new([System.IO.File]::OpenRead($gzPath), [System.IO.Compression.CompressionMode]::Decompress)
$output  = [System.IO.File]::Create($outPath)
$stream.CopyTo($output); $stream.Close(); $output.Close()

# Metadata (~200 MB):
Invoke-WebRequest -Uri 'https://datarepo.eng.ucsd.edu/mcauley_group/data/amazon_2023/raw/meta_categories/meta_Automotive.jsonl.gz' -OutFile staging\amazon\metadata\meta_Automotive.jsonl.gz
# Decompress the same way, changing paths to metadata.
```

Alternatively, download a 10 000-row sample via the script already in the repo:

```powershell
python 04_amazon_hdfs\02_sample_amazon_data.py --input staging\amazon\reviews\Automotive.jsonl --output staging\amazon\reviews\Automotive_sample.jsonl --n 10000
```

### 6. Configure MySQL on Windows

```powershell
# Start the MySQL service (installed by Chocolatey)
Start-Service MySQL80

# Create the database and load data
$env:MYSQL_PASS = 'password'  # change this
mysql -u root -p$env:MYSQL_PASS < 01_mysql\01_create_schema.sql
mysql -u root -p$env:MYSQL_PASS olist_ecommerce < 01_mysql\02_load_data.sql
```

> **Note:** MySQL's `LOAD DATA INFILE` requires the CSV files to be accessible by the MySQL process.  On Windows either place the CSVs in `C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\` or set `secure_file_priv = ""` in `my.ini`.

### 7. Run the pipelines (via Git Bash)

All shell scripts (`.sh`) must be run inside **Git Bash** (or WSL2), not PowerShell or CMD.

```bash
# E-commerce pipeline
export MYSQL_PASS=password
bash 08_run/run_pipeline.sh

# Tokyo Railway pipeline
export JAVA_HOME='/c/Program Files/Eclipse Adoptium/jdk-17.0.x.x-hotspot'
bash 14_tokyo_run/run_pipeline.sh
```

### 8. Run the interactive dashboards

```bash
# E-commerce dashboard  →  http://localhost:8050
python3 08_run/ecommerce_dashboard.py &

# Tokyo railway dashboard  →  http://localhost:8051
python3 14_tokyo_run/tokyo_dashboard.py &
```

### Path notes for Windows agents

- All `.sh` scripts use Unix-style paths (`/user/bigdata/...` for HDFS, relative paths for local files).  When calling `hdfs dfs` commands from PowerShell, the HDFS paths work unchanged; local paths must use Windows separators or be run via Git Bash.
- The `JAVA_HOME` variable must use **forward slashes or double backslashes** when set inside Git Bash.
- Hadoop pseudo-distributed mode on Windows requires running the HDFS daemons (`start-dfs.cmd`, `start-yarn.cmd`) from an **elevated** (Administrator) terminal.

---

## macOS Setup Notes

- Java 21+ required for Hive 4.x
- HiveServer2 requires `hadoop.proxyuser.home.hosts=*` and `hadoop.proxyuser.home.groups=*` in `core-site.xml`
- Beeline uses `script -q` wrapper to work around jline terminal issues on ARM

---

## 🔧 Usage

### E-Commerce Pipeline

```bash
# Full pipeline (all steps)
export MYSQL_PASS=password
bash 08_run/run_pipeline.sh

# Skip specific steps
bash 08_run/run_pipeline.sh --skip-download --skip-mysql --skip-mongo

# Individual steps
bash 02_hdfs/01_hdfs_setup.sh
bash 03_sqoop/01_sqoop_import.sh  # or use Python equivalent below
python3 03_sqoop/03_sqoop_equivalent.py --mappers 4
bash 06_pig/06_run_pig_scripts.sh
```

### Tokyo Railway Pipeline

```bash
# Full pipeline
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
bash 14_tokyo_run/run_pipeline.sh

# Individual steps
bash 10_tokyo_hdfs/01_hdfs_setup.sh
bash 10_tokyo_hdfs/02_upload_to_hdfs.sh
mongosh --file 11_tokyo_mongodb/01_setup_collections.js
bash 12_tokyo_pig/06_run_pig_scripts.sh
```

### Standalone Analytics (No Hadoop)

```bash
python3 08_run/local_analytics.py --archive ./archive
```

---

## 📊 Technology Coverage

| Requirement | E-Commerce | Tokyo Railway |
|-------------|------------|---------------|
| Structured data | Olist CSVs → MySQL → HDFS | GTFS stops, routes, trips, stop_times |
| Semi-structured | Amazon JSONL | Operator metadata JSON |
| External/unstructured → HDFS | Amazon JSONL/media | GTFS JSON metadata |
| SQL → HDFS | Olist (Sqoop-equivalent) | N/A |
| NoSQL storage | 3 MongoDB collections | 6 MongoDB collections |
| PIG processing | 5 scripts | 5 scripts |
| Hive analytics | 13 queries | 15 queries |
| Large-scale data | Amazon 500K sample | 20 operators, 10M+ records |

---

## 📁 Output Locations

### E-Commerce HDFS
- `hdfs:///user/bigdata/ecommerce/raw/structured/` - Olist CSVs
- `hdfs:///user/bigdata/ecommerce/raw/semi_structured/` - Amazon JSONL
- `hdfs:///user/bigdata/ecommerce/processed/` - PIG outputs
- `hdfs:///user/bigdata/ecommerce/analytics/` - Hive results

### Tokyo Railway HDFS
- `hdfs:///user/bigdata/tokyo_transport/raw/gtfs/` - GTFS by operator
- `hdfs:///user/bigdata/tokyo_transport/processed/` - PIG outputs
- `hdfs:///user/bigdata/tokyo_transport/analytics/hive/` - Hive results

### MongoDB Collections
- `ecommerce_bigdata`: amazon_reviews, amazon_products, olist_orders_enriched
- `tokyo_transport`: operators, routes, stations, trips, schedules, network_stats

---

## 📝 Deliverables Checklist

| Deliverable | Status |
|-------------|--------|
| Dataset documentation | ✅ PRD + README |
| HDFS directory structure | ✅ Both projects |
| MySQL schema | ✅ Olist (9 tables) |
| SQL-to-HDFS commands | ✅ Sqoop-equivalent Python |
| MongoDB collections | ✅ 9 total collections |
| PIG scripts | ✅ 10 total scripts |
| Hive tables and queries | ✅ 27 total tables/queries |
| Output datasets | ✅ HDFS + ORC + MongoDB |
| Architecture diagram | ✅ In README |
| Final report | ✅ README files |

---

## 🔧 Troubleshooting

### HiveServer2 Connection Issues
```bash
# Ensure proxyuser is configured in core-site.xml
# Restart HDFS and HiveServer2
```

### PIG Job Failures
```bash
# Check commons-collections JAR is available
# Set PIG_CLASSPATH=/opt/homebrew/Cellar/pig/0.18.0/libexec/lib/hadoop3-runtime/commons-collections-3.2.2.jar
```

### MongoDB Import Errors
```bash
# Ensure mongoimport version matches MongoDB server
# Check JSONL file encoding (UTF-8)
```

---

**For detailed project information, see the individual project directories.**
