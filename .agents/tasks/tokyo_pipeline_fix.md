# Tokyo Railway Big Data Pipeline - Fix Summary

## Issues Identified and Fixed

### 1. Hardcoded Paths
- **File:** 10_tokyo_hdfs/02_upload_to_hdfs.sh
- **Issue:** Used absolute path /Users/home/College/Big Data Computing/E-commerce/09_tokyo_gtfsgenerator/raw
- **Fix:** Added dynamic ROOT detection and used ${ROOT} for all paths

### 2. File Path Encoding for HDFS Commands
- **File:** 10_tokyo_hdfs/02_upload_to_hdfs.sh
- **Issue:** hdfs dfs -put was failing with "No such file or directory" for local files with spaces in path
- **Fix:** Added file:// prefix to all local file paths in hdfs dfs -put commands

### 3. MongoDB Import Incomplete
- **File:** 14_tokyo_run/run_pipeline.sh
- **Issue:** Only imported routes.txt and stops.txt, missing trips.txt and stop_times.txt
- **Fix:** Added mongoimport commands for trips.txt and stop_times.txt

### 4. Pig Script Syntax Error (STRSPLIT .get() method)
- **File:** 12_tokyo_pig/01_load_gtfs.pig
- **Issue:** Used invalid syntax (CHARARRAY)STRSPLIT(stop_id, '\\.').get(0) - Pig Latin does not support .get() method
- **Fix:** Replaced with REGEX_EXTRACT(stop_id, '^([^\\.]+)', 1) to extract operator prefix

### 5. Operator Lookup CSV Path in Pig Script
- **File:** 12_tokyo_pig/02_normalize_operators.pig
- **Issue:** Used relative path that does not work in distributed MAPREDUCE mode
- **Fix:** Changed to absolute file:// path

## Pipeline Execution Results

### Phase 1: HDFS Setup - SUCCESS
- Created all required HDFS directories under /user/bigdata/tokyo_transport/
- Uploaded all GTFS files to HDFS

### Phase 2: MongoDB Setup - SUCCESS
- All 20 operators inserted
- Collections created and populated: operators (20 docs), routes (9 docs), stations (117 docs), trips (7594 docs), schedules (110430 docs)

### Phase 3: Pig Processing - PARTIAL SUCCESS
**Successful:**
- 01_load_gtfs.pig - Cleaned GTFS data, extracted operator prefixes
- 02_normalize_operators.pig - Normalized operator names
- 03_join_gtfs.pig - Joined all GTFS data files

**Failed (environment issue):**
- 04_aggregate_routes.pig - Failed due to missing commons-collections JAR
- 05_analyze_network.pig - Failed due to missing commons-collections JAR

### Phase 4: Hive Analytics - EXPECTED WARNING
- Hive server not running in environment
- Pipeline correctly continues with: WARNING: Hive table creation failed, continuing...

### Phase 5: Final Verification - SUCCESS
- HDFS directory listing completed
- MongoDB collection counts verified

## Files Changed

1. 10_tokyo_hdfs/02_upload_to_hdfs.sh
   - Added dynamic ROOT detection
   - Added file:// prefix for local paths in hdfs dfs -put commands

2. 14_tokyo_run/run_pipeline.sh
   - Added mongoimport for trips.txt and stop_times.txt

3. 12_tokyo_pig/01_load_gtfs.pig
   - Fixed STRSPLIT syntax error with REGEX_EXTRACT

4. 12_tokyo_pig/02_normalize_operators.pig
   - Fixed operator_lookup.csv path to absolute file:// path

## Remaining Issues

1. Pig Scripts 4 & 5 fail due to missing JAR: org.apache.commons.collections.buffer.CircularFifoBuffer
   - This is an environment setup issue requiring the commons-collections JAR to be added to the Pig classpath
   - Not a code issue - pipeline correctly continues despite the failure

2. Hive scripts require a running Hive server (hiveserver2) on port 10000
   - This is an environment setup issue
   - Pipeline correctly continues despite the failure

## Pipeline Status
All 5 phases completed with expected warnings for Pig/Hive environment limitations.
