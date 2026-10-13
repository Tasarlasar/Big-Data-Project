# Tokyo Railway Big Data Pipeline

Big Data Computing CAT II – Project 2

This pipeline processes Tokyo Metro GTFS (General Transit Feed Specification) data using Hadoop, Pig, Hive, and MongoDB.

---

## Prerequisites

Before running the pipeline, ensure the following are installed and running:

| Tool | Minimum Version | Purpose |
|------|-----------------|---------|
| Hadoop | 3.3.0+ | Distributed storage and processing |
| Pig | 0.17.0+ | High-level data flow language |
| Hive | 3.1.0+ | SQL-like analytics on HDFS |
| MongoDB | 5.0+ | NoSQL document storage |
| mongoimport | - | MongoDB data import utility |
| OpenJDK | 17+ | Java runtime for Hadoop/Pig/Hive |

### Starting Services

```bash
# Start Hadoop
start-dfs.sh
start-yarn.sh

# Start Hive Metastore and Server (in separate terminals)
hive --service metastore &
hive --service hiveserver2 &

# Start MongoDB
mongod --fork --logpath /var/log/mongodb.log --bind_ip localhost
```

---

## How to Run the Pipeline

```bash
cd /Users/home/College/Big Data Computing/E-commerce
bash 14_tokyo_run/run_pipeline.sh
```

The script will:
1. Set up HDFS directories and upload GTFS data
2. Create MongoDB collections and import GTFS CSV files
3. Run Pig scripts for data loading, normalization, and joining
4. Create Hive tables and execute analytics queries
5. Verify outputs and display collection counts

---

## Expected Outputs

### Phase 1: HDFS Setup

**Output Directories:**
- `/user/bigdata/tokyo_transport/raw/gtfs/` – Raw GTFS CSV files
- `/user/bigdata/tokyo_transport/staging/` – Intermediate processing data

### Phase 2: MongoDB Setup

**Collections Created:**
- `operators` – Tokyo railway operators (e.g., JR East, Tokyo Metro)
- `routes` – Route definitions from routes.txt
- `stations` – Station information from stops.txt
- `trips` – Trip information
- `schedules` – Schedule/timetable data

### Phase 3: Pig Processing

**Pig Output Files:**
- `pig_01.log` – GTFS loading script output
- `pig_02.log` – Operator normalization script output
- `pig_03.log` – GTFS join script output
- `pig_04.log` – Route aggregation script output
- `pig_05.log` – Network analysis script output

HDFS outputs:
- `/user/bigdata/tokyo_transport/pig/normalized/` – Normalized data
- `/user/bigdata/tokyo_transport/pig/joined/` – Joined datasets
- `/user/bigdata/tokyo_transport/pig/aggregated/` – Aggregated route statistics

### Phase 4: Hive Analytics

**Hive Tables:**
- `tokyo_routes` – Aggregated route information
- `tokyo_stations` – Station metadata
- `tokyo_network_stats` – Network-wide statistics

**Analytics Results:**
- Total route count by operator
- Station density analysis
- Connection patterns
- Network coverage metrics

---

## HDFS Directory Structure

```
/user/bigdata/tokyo_transport/
├── raw/
│   └── gtfs/
│       ├── routes.txt
│       ├── stops.txt
│       ├── trips.txt
│       ├── stop_times.txt
│       └── agencies.txt
├── staging/
│   └── pig_intermediate/
├── pig/
│   ├── normalized/
│   ├── joined/
│   └── aggregated/
└── hive/
    └── outputs/
```

---

## MongoDB Collections

| Collection | Source | Description |
|------------|--------|-------------|
| `operators` | JS seeding | Railway operators (JR East, Tokyo Metro, etc.) |
| `routes` | GTFS routes.txt | Route definitions (line IDs, names, types) |
| `stations` | GTFS stops.txt | Station locations and metadata |
| `trips` | GTFS trips.txt | Trip information per route |
| `schedules` | GTFS stop_times.txt | Stop arrival/departure times |

---

## Troubleshooting

### Common Issues

1. **Hive jline terminal errors**: The pipeline uses `beeline` with `--silent=false` to avoid terminal issues on macOS ARM.

2. **MongoDB connection refused**: Ensure `mongod` is running and bound to `localhost:27017`.

3. **HDFS permission denied**: Run `hdfs dfs -chmod -R 777 /user/bigdata/tokyo_transport` or adjust permissions.

4. **Pig script failures**: Check `${LOG_DIR}/pig_XX.log` for specific errors.

---

## Pipeline Log Location

All phase logs are written to:
- `/Users/home/College/Big Data Computing/E-commerce/14_tokyo_run/run_pipeline.log`

Each Pig phase logs to its respective script directory:
- `/Users/home/College/Big Data Computing/E-commerce/12_tokyo_pig/pig_01.log` through `pig_05.log`
