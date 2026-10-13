-- =============================================================================
-- PIG Script 1: Filter and Clean Amazon Automotive Reviews
-- Big Data Computing CAT II – Project 1
--
-- Input:  HDFS raw Amazon reviews JSONL
-- Output: HDFS processed/reviews_filtered
--
-- Operations demonstrated: LOAD, FILTER, FOREACH, STORE
-- =============================================================================

-- ── 1. Load raw Amazon reviews ────────────────────────────────────────────────
-- JsonLoader parses JSONL (one JSON object per line). NOTE: Pig's builtin
-- JsonLoader maps fields BY POSITION, so the schema below must list the fields
-- in exactly the order they appear in the source JSON records:
--   rating, title, text, images, asin, parent_asin, user_id, timestamp,
--   helpful_vote, verified_purchase
-- (The 'images' array is loaded as a bag placeholder and simply ignored.)
raw_reviews = LOAD '/user/bigdata/ecommerce/raw/semi_structured/amazon_reviews/Automotive.jsonl'
              USING JsonLoader(
                  'rating:float,
                   title:chararray,
                   text:chararray,
                   images:{(t:chararray)},
                   asin:chararray,
                   parent_asin:chararray,
                   user_id:chararray,
                   timestamp:long,
                   helpful_vote:int,
                   verified_purchase:chararray'
              );

-- ── 2. Filter out invalid records ────────────────────────────────────────────
-- Keep only records with non-null ASIN, user_id, and a valid rating (1–5)
valid_reviews = FILTER raw_reviews BY
    (asin       IS NOT NULL) AND
    (user_id    IS NOT NULL) AND
    (rating     IS NOT NULL) AND
    (rating     >= 1.0)      AND
    (rating     <= 5.0);

-- ── 3. Standardise fields ─────────────────────────────────────────────────────
cleaned_reviews = FOREACH valid_reviews GENERATE
    asin,
    parent_asin,
    user_id,
    (float) rating                                   AS rating,
    (title IS NOT NULL ? title : 'NO_TITLE')         AS title,
    (text  IS NOT NULL ? text  : '')                 AS review_text,
    (helpful_vote IS NOT NULL ? helpful_vote : 0)    AS helpful_vote,
    (verified_purchase == 'true' ? 1 : 0)            AS is_verified,
    timestamp;

-- ── 4. Remove duplicate (user_id, asin) pairs ────────────────────────────────
-- A user may have multiple reviews for the same product; keep the latest one.
grouped_by_user_asin = GROUP cleaned_reviews BY (user_id, asin);

deduped_reviews = FOREACH grouped_by_user_asin {
    sorted = ORDER cleaned_reviews BY timestamp DESC;
    top1   = LIMIT sorted 1;
    GENERATE FLATTEN(top1);
};

-- ── 5. Count for verification ─────────────────────────────────────────────────
review_count = FOREACH (GROUP deduped_reviews ALL) GENERATE COUNT(deduped_reviews) AS total;
DUMP review_count;

-- ── 6. Store output ───────────────────────────────────────────────────────────
-- Remove existing output directory (like Sqoop --delete-target-dir)
rmf '/user/bigdata/ecommerce/processed/reviews_filtered'

STORE deduped_reviews
    INTO '/user/bigdata/ecommerce/processed/reviews_filtered'
    USING PigStorage(',');
