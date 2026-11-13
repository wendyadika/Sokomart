set search_path to sokomart;

--q21
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(i.line_total) AS revenue
FROM sokomart.customers c
JOIN sokomart.orders o
    ON o.customer_id = c.customer_id
JOIN sokomart.order_items i
    ON i.order_id = o.order_id
WHERE c.county = 'Kisumu'
  AND o.order_status = 'completed'
  AND o.order_date >= '2026-09-01'
  AND o.order_date < '2026-10-01'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY revenue DESC;

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(i.line_total) AS revenue
FROM sokomart.customers c
JOIN sokomart.orders o
    ON o.customer_id = c.customer_id
JOIN sokomart.order_items i
    ON i.order_id = o.order_id
WHERE c.county = 'Kisumu'
  AND o.order_status = 'completed'
  AND o.order_date >= '2026-09-01'
  AND o.order_date < '2026-10-01'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY revenue DESC;

/*
 QUERY PLAN ANALYSIS

top_node: Sort

join_methods_used:
Hash Join, Nested Loop

scan_on_orders:
Index Scan using idx_orders_order_date

scan_on_customers:
Bitmap Heap Scan
Bitmap Index Scan using idx_customers_county

estimated_vs_actual_rows_orders:
Estimated = 2,090
Actual = 2,061

planning_ms: 21.210

execution_ms: 3.875

result_rows: 91

OBSERVATIONS:

1. PostgreSQL used the order date index to retrieve
   September 2026 orders.

2. The customer county index helped identify
   customers living in Kisumu.

3. The order items index helped retrieve items
   belonging to qualifying orders.

4. PostgreSQL used Hash Join and Nested Loop
   operations to combine the tables.

5. The query execution time was 3.875 milliseconds.
*/
 

