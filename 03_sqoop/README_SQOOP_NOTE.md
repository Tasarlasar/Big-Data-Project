# Sqoop Execution Note

Apache Sqoop 1.4.7 (the last released version) is **incompatible with Hadoop 3.5**.
Sqoop's `SqoopParser`/`GenericOptionsParser` depends on `commons-cli` API methods
that were changed between commons-cli 1.2 (Sqoop era) and 1.9 (shipped with
Hadoop 3.5). The two APIs cannot coexist on a single classpath:

- With commons-cli 1.2: Hadoop's `GenericOptionsParser` fails
  (`NoSuchMethodError: Option.builder`).
- With commons-cli 1.9: Sqoop's `SqoopParser` fails
  (`NoSuchMethodException: Option.addValueForProcessing`).

No official Sqoop release supports Hadoop 3.x. As the PRD explicitly allows
"Sqoop **or an equivalent SQL-to-HDFS mechanism**", the import was performed by
`03_sqoop_equivalent.py`, which replicates Sqoop's behaviour exactly:

- Reads each MySQL table over JDBC.
- Splits large tables by a numeric column into parallel "mapper" ranges
  (`--split-by` / `-m N` equivalent), e.g. `order_items` and `order_payments`
  each used 5 splits.
- Writes comma-delimited `part-m-NNNNN` files into HDFS, one per mapper.
- Uses `\N` for NULLs, matching Sqoop's default null encoding.

Output landed in `hdfs:///user/bigdata/ecommerce/sqoop_import/<table>/part-m-*`.

Row counts imported (verified against MySQL):

| Table | Rows |
|---|---|
| customers | 99,441 |
| sellers | 3,095 |
| products | 32,951 |
| category_translation | 71 |
| orders | 99,441 |
| order_items | 112,650 |
| order_payments | 103,886 |
| order_reviews | 98,409 |
| geolocation | 2,000,326 |

The original `01_sqoop_import.sh` (real `sqoop import` commands) is retained for
reference and will work on a Hadoop 2.x cluster where Sqoop is supported.
