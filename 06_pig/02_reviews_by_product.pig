-- =============================================================================
-- PIG Script 2: Aggregate Reviews by Product (ASIN)
-- Big Data Computing CAT II – Project 1
--
-- Input:  processed/reviews_filtered  (output of script 01)
-- Output: processed/reviews_by_product
--
-- Operations demonstrated: LOAD, GROUP, FOREACH, ORDER, STORE
-- =============================================================================

-- ── 1. Load filtered reviews ──────────────────────────────────────────────────
filtered = LOAD '/user/bigdata/ecommerce/processed/reviews_filtered'
           USING PigStorage(',')
           AS (asin:chararray,
               parent_asin:chararray,
               user_id:chararray,
               rating:float,
               title:chararray,
               review_text:chararray,
               helpful_vote:int,
               is_verified:int,
               timestamp:long);

-- ── 2. Group by ASIN ──────────────────────────────────────────────────────────
grouped_by_asin = GROUP filtered BY asin;

-- ── 3. Compute per-product aggregates ────────────────────────────────────────
reviews_by_product = FOREACH grouped_by_asin GENERATE
    group                               AS asin,
    COUNT(filtered)                     AS review_count,
    AVG(filtered.rating)                AS avg_rating,
    MIN(filtered.rating)                AS min_rating,
    MAX(filtered.rating)                AS max_rating,
    SUM(filtered.helpful_vote)          AS total_helpful_votes,
    SUM(filtered.is_verified)           AS verified_count,
    -- percentage of verified reviews
    (float) SUM(filtered.is_verified) / (float) COUNT(filtered) * 100.0 AS pct_verified;

-- ── 4. Order by review count descending ──────────────────────────────────────
top_products = ORDER reviews_by_product BY review_count DESC;

-- ── 5. Show top 20 products ───────────────────────────────────────────────────
top20 = LIMIT top_products 20;
DUMP top20;

-- ── 6. Store full aggregated output ──────────────────────────────────────────
-- Remove existing output directory (like Sqoop --delete-target-dir)
rmf '/user/bigdata/ecommerce/processed/reviews_by_product'

STORE reviews_by_product
    INTO '/user/bigdata/ecommerce/processed/reviews_by_product'
    USING PigStorage(',');
