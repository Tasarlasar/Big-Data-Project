#!/usr/bin/env python3
"""
Amazon Reviews'23 – Create a manageable sample from a large JSONL file.
Big Data Computing CAT II – Project 1

If the full Automotive dataset is too large for the lab environment, this
script draws a random sample (default 500 000 records) and writes a smaller
JSONL file that can be loaded into HDFS / MongoDB.

Usage:
    python3 02_sample_amazon_data.py \
        --input  /tmp/amazon_staging/reviews/Automotive.jsonl \
        --output /tmp/amazon_staging/reviews/Automotive_sample.jsonl \
        --n      500000

    python3 02_sample_amazon_data.py \
        --input  /tmp/amazon_staging/metadata/meta_Automotive.jsonl \
        --output /tmp/amazon_staging/metadata/meta_Automotive_sample.jsonl \
        --n      100000
"""

import argparse
import json
import random
import sys


def reservoir_sample(input_path: str, output_path: str, n: int, seed: int = 42) -> None:
    """Reservoir sampling so we don't need to know the file size up front."""
    rng = random.Random(seed)
    reservoir: list[dict] = []
    total = 0

    print(f"Reading {input_path} …", flush=True)
    with open(input_path, "r", encoding="utf-8") as fh:
        for i, line in enumerate(fh):
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue  # skip malformed lines

            total += 1
            if len(reservoir) < n:
                reservoir.append(record)
            else:
                j = rng.randint(0, i)
                if j < n:
                    reservoir[j] = record

            if total % 1_000_000 == 0:
                print(f"  Processed {total:,} lines …", flush=True)

    print(f"Total lines read: {total:,}")
    print(f"Sample size:      {len(reservoir):,}")

    print(f"Writing {output_path} …", flush=True)
    with open(output_path, "w", encoding="utf-8") as fh:
        for record in reservoir:
            fh.write(json.dumps(record, ensure_ascii=False) + "\n")

    print("Done.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Reservoir-sample a JSONL file.")
    parser.add_argument("--input",  required=True, help="Input JSONL file path")
    parser.add_argument("--output", required=True, help="Output JSONL file path")
    parser.add_argument("--n",      type=int, default=500_000, help="Sample size (default 500000)")
    parser.add_argument("--seed",   type=int, default=42,      help="Random seed")
    args = parser.parse_args()

    reservoir_sample(args.input, args.output, args.n, args.seed)


if __name__ == "__main__":
    main()
