set search_path to sokomart;
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'sokomart'
  AND table_name = 'payment_staging'
ORDER BY ordinal_position;

SELECT COUNT(*) AS total_staging_records
FROM sokomart.payment_staging;

--check duplicates
WITH ranked_payments AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY payment_id
            ORDER BY loaded_at, staging_id
        ) AS row_num
    FROM sokomart.payment_staging
)
SELECT
    payment_id,
    order_id,
    amount,
    loaded_at,
    staging_id,
    row_num
FROM ranked_payments
WHERE row_num > 1
ORDER BY payment_id
LIMIT 20;

--count duplicates
WITH ranked_payments AS (
    SELECT
        payment_id,
        ROW_NUMBER() OVER (
            PARTITION BY payment_id
            ORDER BY loaded_at, staging_id
        ) AS row_num
    FROM sokomart.payment_staging
),
duplicate_summary AS (
    SELECT
        payment_id,
        COUNT(*) AS copies
    FROM ranked_payments
    GROUP BY payment_id
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS duplicated_payment_ids,
    SUM(copies - 1) AS extra_rows_to_delete,
    MAX(copies) AS maximum_copies
FROM duplicate_summary;

--records before deduplication
SELECT COUNT(*) AS records_before_deduplication

WITH ranked_payments AS (
    SELECT
        staging_id,
        ROW_NUMBER() OVER (
            PARTITION BY payment_id
            ORDER BY loaded_at, staging_id
        ) AS row_num
    FROM sokomart.payment_staging
)
DELETE FROM sokomart.payment_staging AS ps
USING ranked_payments AS rp
WHERE ps.staging_id = rp.staging_id
  AND rp.row_num > 1;

SELECT COUNT(*) AS records_after_deduplication
FROM sokomart.payment_staging;

SELECT
    payment_id,
    COUNT(*) AS copies
FROM sokomart.payment_staging
GROUP BY payment_id
HAVING COUNT(*) > 1; --0

SELECT
    (SELECT COUNT(*)
     FROM sokomart.payment_staging) AS staging_records,
    (SELECT COUNT(DISTINCT payment_id)
     FROM sokomart.payment_staging) AS unique_payment_ids,
    (SELECT ROUND(SUM(amount), 2)
     FROM sokomart.payment_staging) AS staging_total,
    (SELECT ROUND(SUM(p.amount), 2)
     FROM sokomart.payments p
     WHERE EXISTS (
         SELECT 1
         FROM sokomart.payment_staging ps
         WHERE ps.payment_id = p.payment_id
     )) AS original_payments_total;
-- matching both at 2400

CREATE UNIQUE INDEX idx_payment_staging_unique
ON sokomart.payment_staging(payment_id);
DROP INDEX IF EXISTS sokomart.idx_payment_staging_unique;

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'sokomart'
  AND tablename = 'payment_staging';

INSERT INTO sokomart.payment_staging (
    payment_id,
    staging_id,
    order_id,
    payment_date,
    payment_method
)
SELECT
    payment_id,
    (SELECT COALESCE(MAX(staging_id), 0) + 1
     FROM sokomart.payment_staging),
    order_id,
    payment_date,
    payment_method
FROM sokomart.payment_staging
LIMIT 1;
--eeror

select * from payment_staging;
    