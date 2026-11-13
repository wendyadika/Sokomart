set search_path to sokomart;
WITH customer_months AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', order_date)::date AS month_start
    FROM sokomart.orders
    WHERE order_status = 'completed'
),
numbered_months AS (
    SELECT
        customer_id,
        month_start,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY month_start
        ) AS row_num
    FROM customer_months
),
grouped_months AS (
    SELECT
        customer_id,
        month_start,
        month_start - (
            row_num * INTERVAL '1 month'
        ) AS streak_group
    FROM numbered_months
),
customer_streaks AS (
    SELECT
        customer_id,
        MIN(month_start) AS streak_start,
        MAX(month_start) AS streak_end,
        COUNT(*) AS consecutive_months
    FROM grouped_months
    GROUP BY customer_id, streak_group
    HAVING COUNT(*) >= 3
),
ranked_streaks AS (
    SELECT
        customer_id,
        streak_start,
        streak_end,
        consecutive_months,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY consecutive_months DESC, streak_start
        ) AS streak_rank
    FROM customer_streaks
)
SELECT
    customer_id,
    streak_start,
    streak_end,
    consecutive_months
FROM ranked_streaks
WHERE streak_rank = 1
ORDER BY consecutive_months DESC, customer_id
LIMIT 10;

--verify atleast 1 qualifying streak
WITH customer_months AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', order_date)::date AS month_start
    FROM sokomart.orders
    WHERE order_status = 'completed'
),
numbered_months AS (
    SELECT
        customer_id,
        month_start,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY month_start
        ) AS row_num
    FROM customer_months
),
grouped_months AS (
    SELECT
        customer_id,
        month_start,
        month_start - (
            row_num * INTERVAL '1 month'
        ) AS streak_group
    FROM numbered_months
),
streaks AS (
    SELECT
        customer_id,
        COUNT(*) AS consecutive_months
    FROM grouped_months
    GROUP BY customer_id, streak_group
    HAVING COUNT(*) >= 3
)
SELECT
    COUNT(DISTINCT customer_id) AS customers_with_3_month_streaks,
    MAX(consecutive_months) AS longest_streak_months
FROM streaks;