set search_path to sokomart;

SELECT
    category,
    ROUND(AVG(unit_price), 2) AS original_average_price
FROM sokomart.products
WHERE category = 'Beauty'
GROUP BY category;

BEGIN;

UPDATE sokomart.products
SET unit_price = ROUND(unit_price * 0.90, 2)
WHERE category = 'Beauty';

SELECT
    category,
    ROUND(AVG(unit_price), 2) AS discounted_average_price
FROM sokomart.products
WHERE category = 'Beauty'
GROUP BY category;
ROLLBACK;

SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166);

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'sokomart'
  AND table_name = 'audit_logs'
ORDER BY ordinal_position;

BEGIN;

UPDATE sokomart.products
SET stock_quantity = stock_quantity + 40
WHERE product_id = 59;

-- Verify the updated stock
SELECT product_id, stock_quantity
FROM sokomart.products
WHERE product_id = 59;

SAVEPOINT after_restock;

UPDATE sokomart.products
SET stock_quantity = 0
WHERE product_id = 166;

-- Check the change
SELECT product_id, stock_quantity
FROM sokomart.products
WHERE product_id = 166;
ROLLBACK TO SAVEPOINT after_restock;
COMMIT;

SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (59, 166);

-- Demonstrate a constraint violation
SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id = 166;
BEGIN;

UPDATE sokomart.products
SET stock_quantity = stock_quantity + 1
WHERE product_id = 166;

UPDATE sokomart.products
SET stock_quantity = -5
WHERE product_id = 166;
/*SQL Error [23514]: ERROR: new row for relation "products" violates check constraint "chk_products_stock"
  Detail: Failing row contains (166, Maasai Leather Handbag Crossbody, Fashion, Maasai Leather, 8850.00, 5594.97, -5, 2024-04-20 20:32:00, active).
*/
commit;

SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id = 166;



