set search_path to sokomart;
SET search_path TO sokomart;

-- customer access paths
CREATE INDEX IF NOT EXISTS idx_customers_county            ON sokomart.customers (county);
CREATE INDEX IF NOT EXISTS idx_customers_registration_date ON sokomart.customers (registration_date);

-- product access paths
CREATE INDEX IF NOT EXISTS idx_products_category           ON sokomart.products (category);

-- order access paths
CREATE INDEX IF NOT EXISTS idx_orders_customer_id          ON sokomart.orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_date           ON sokomart.orders (order_date);
CREATE INDEX IF NOT EXISTS idx_orders_status_date          ON sokomart.orders (order_status, order_date);
CREATE INDEX IF NOT EXISTS idx_orders_customer_date        ON sokomart.orders (customer_id, order_date);

-- order item access paths (uq_order_items_order_product already covers order_id lookups)
CREATE INDEX IF NOT EXISTS idx_order_items_product_id      ON sokomart.order_items (product_id);

-- payment access paths
CREATE INDEX IF NOT EXISTS idx_payments_order_id           ON sokomart.payments (order_id);
CREATE INDEX IF NOT EXISTS idx_payments_status_method      ON sokomart.payments (payment_status, payment_method);
CREATE INDEX IF NOT EXISTS idx_payments_payment_date       ON sokomart.payments (payment_date);

-- history tables
CREATE INDEX IF NOT EXISTS idx_price_history_product_id    ON sokomart.product_price_history (product_id);
CREATE INDEX IF NOT EXISTS idx_status_history_order_id     ON sokomart.order_status_history (order_id);

ANALYZE sokomart.customers, sokomart.products, sokomart.orders,
        sokomart.order_items, sokomart.payments;

DROP INDEX IF EXISTS sokomart.idx_customers_county, sokomart.idx_customers_registration_date, sokomart.idx_orders_customer_date;

ANALYZE;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    order_date,
    total_amount
FROM sokomart.orders
WHERE customer_id = 408
ORDER BY order_date;

/*
QUERY 1: CUSTOMER ORDERS - CUSTOMER 408

Top node: Sort
Scan method: Bitmap Heap Scan
Index scan: Bitmap Index Scan
Index used: idx_orders_customer_id

Estimated rows: 9
Actual rows: 11

Planning time: 0.159 ms
Execution time: 0.104 ms

Shared buffer hits: 14
Heap blocks accessed: 12

Observation:
PostgreSQL uses the customer_id index to locate
the customer's orders, retrieves the matching rows
using a Bitmap Heap Scan, and sorts them by order_date.
*/

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM sokomart.payments
WHERE order_id = 25000;

/*
QUERY 2: PAYMENT LOOKUP - ORDER ID 25000

Scan method: Index Scan
Index used: idx_payments_order_id

Estimated rows: 1
Actual rows: 1

Planning time: 0.246 ms
Execution time: 1.834 ms

Shared buffer hits: 1
Shared buffer reads: 2
Index searches: 1

Observation:
PostgreSQL uses the index on order_id to locate
the matching payment record. The estimated row
count matches the actual row count.
*/

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    quantity,
    line_total
FROM sokomart.order_items
WHERE product_id = 71;

/*
QUERY 3: PRODUCT ORDER ITEMS - PRODUCT ID 71

Scan method: Bitmap Heap Scan
Index scan: Bitmap Index Scan
Index used: idx_order_items_product_id

Estimated rows: 201
Actual rows: 358

Planning time: 0.156 ms
Execution time: 0.547 ms

Shared buffer hits: 304
Shared buffer reads: 1
Heap blocks accessed: 303
Index searches: 1

Observation:
PostgreSQL uses the product_id index to identify
matching order items, then retrieves the records
using a Bitmap Heap Scan. The actual number of
rows (358) is higher than the estimated 201 rows.
*/

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    order_date,
    total_amount
FROM sokomart.orders
WHERE customer_id = 408
ORDER BY order_date;

/*
QUERY 1: CUSTOMER ORDERS - AFTER INDEXING

Top node: Sort
Scan method: Bitmap Heap Scan
Index scan: Bitmap Index Scan
Index used: idx_orders_customer_date

Estimated rows: 9
Actual rows: 11

Planning time: 0.298 ms
Execution time: 0.071 ms

Shared buffer hits: 11
Shared buffer reads: 2

Observation:
PostgreSQL uses the composite customer/date index
to retrieve customer 408's orders. Execution time
decreased from 0.104 ms to 0.071 ms compared with
the previous plan.
*/

/*
QUERY 2: PAYMENT LOOKUP - AFTER INDEXING

Scan method: Index Scan
Index used: idx_payments_order_id

Estimated rows: 1
Actual rows: 1

Planning time: 0.143 ms
Execution time: 0.018 ms

Shared buffer hits: 3
Index searches: 1

Observation:
PostgreSQL efficiently locates the payment using
the order_id index. The actual row count matches
the estimated row count.
*/

/*
QUERY 3: PRODUCT ORDER ITEMS - AFTER INDEXING

Scan method: Bitmap Heap Scan
Index scan: Bitmap Index Scan
Index used: idx_order_items_product_id

Estimated rows: 203
Actual rows: 358

Planning time: 0.164 ms
Execution time: 0.465 ms

Shared buffer hits: 305
Heap blocks accessed: 303
Index searches: 1

Observation:
PostgreSQL uses the product_id index to locate
matching order items and retrieves them through
a Bitmap Heap Scan.
*/

/*
+----------------------+------------------------+-------------------------+----------------+
| Query                | Previous execution (ms)| After-index (ms)        | Change         |
+----------------------+------------------------+-------------------------+----------------+
| Customer orders      | 0.104                  | 0.071                   | 31.7% faster   |
| Payment lookup       | 1.834                  | 0.018                   | 99.0% faster   |
| Product order items  | 0.547                  | 0.465                   | 15.0% faster   |
+----------------------+------------------------+-------------------------+----------------+
*/

--Create partial index
CREATE INDEX IF NOT EXISTS idx_orders_pending_date
ON sokomart.orders(order_date)
WHERE order_status = 'pending';

--testing it
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    order_date,
    total_amount
FROM sokomart.orders
WHERE order_status = 'pending'
  AND order_date < '2026-10-25';

/*
PARTIAL INDEX TEST RESULTS

Index name: idx_orders_pending_date
Scan method: Index Scan

Estimated rows: 417
Actual rows: 203

Planning time: 1.517 ms
Execution time: 0.077 ms

Shared buffer hits: 7
Shared buffer reads: 2
Index searches: 1

Observation:
PostgreSQL successfully used the partial index
idx_orders_pending_date to retrieve pending orders
with an order_date before 25 October 2026.

The partial index improves access to the relevant
subset of orders without indexing every order.
*/

SELECT
    'idx_orders_pending_date' AS index_name,
    pg_size_pretty(
        pg_relation_size('sokomart.idx_orders_pending_date')
    ) AS index_size,
    pg_relation_size(
        'sokomart.idx_orders_pending_date'
    ) AS size_bytes
UNION ALL
SELECT
    'idx_orders_order_date',
    pg_size_pretty(
        pg_relation_size('sokomart.idx_orders_order_date')
    ),
    pg_relation_size(
        'sokomart.idx_orders_order_date'
    );

/*
PARTIAL INDEX SIZE COMPARISON

+---------------------------+------------+-------------+
| Index Name                | Index Size | Size (Bytes)|
+---------------------------+------------+-------------+
| idx_orders_pending_date   | 32 kB      | 32,768      |
| idx_orders_order_date     | 1,112 kB   | 1,138,688   |
+---------------------------+------------+-------------+

Finding:
The partial index is approximately 97.1% smaller
than the full order-date index.

Explanation:
The partial index stores entries only for pending
orders, reducing storage requirements compared
to the full index, which covers all orders.

findings demonstrate that:
1. Indexes can improve query execution time by reducing the amount of data PostgreSQL needs to search.
2. Different index scan methods, including Index Scan and Bitmap Heap Scan, are selected depending on the query and data distribution.
3. A partial index can reduce storage requirements while efficiently supporting queries targeting a specific subset of records.

*/