set search_path to sokomart;
select * from customers;
select * from order_items;
select * from order_status_history;
select * from orders;
select * from payments;
select * from payment_staging;
select * from product_price_history;
select * from products;
select * from audit_logs;

--q11
with customer_revenue as (
select o.customer_id, sum(oi.line_total) as lifetime_revenue
from orders o join order_items oi on o.order_id = oi.order_id
where o.order_status = 'completed'
group by o.customer_id
),
customer_tiers as (
select customer_id, lifetime_revenue,
case
    when lifetime_revenue >= 1000000 then 'Platinum'
    when lifetime_revenue >= 500000 then 'Gold'
    when lifetime_revenue >= 100000 then 'Silver'
         else 'Bronze'
        end as tier
    from customer_revenue
)
select tier, count(*) AS customer_count, min(lifetime_revenue) as min_revenue,
max(lifetime_revenue) AS max_revenue, round(avg(lifetime_revenue), 2) as avg_revenue,
round(100.0 * SUM(lifetime_revenue) /NULLIF((select SUM(lifetime_revenue) from customer_revenue
), 0),2) as revenue_share_pct
from customer_tiers
group by tier
order by
    case tier
        when 'Platinum' then 1
        when 'Gold' then 2
        when 'Silver' then 3
        when 'Bronze' then 4
    end;

-- q12
select c.customer_id, c.first_name || ' ' || c.last_name as full_name,
count(DISTINCT p.product_id) AS product_count, STRING_AGG(DISTINCT p.product_name,
        '; ' ORDER BY p.product_name
    ) AS products_ordered
from customers c
join orders o on c.customer_id = o.customer_id
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
where c.county = 'Mombasa'
and o.order_status <> 'cancelled'
and o.order_date >= '2026-10-01'
and o.order_date < '2026-11-01'
and exists (select 1
from orders o2 where o2.customer_id = c.customer_id
and o2.order_status <> 'cancelled'
and o2.order_date >= '2026-10-01'
and o2.order_date < '2026-11-01'
  )
group by c.customer_id, c.first_name, c.last_name
ORDER BY product_count DESC, c.customer_id;

select COUNT(*) AS qualifying_customers
from customers c
where c.county = 'Mombasa'
and exists(select 1
      from orders o
      WHERE o.customer_id = c.customer_id
        AND o.order_status <> 'cancelled'
        AND o.order_date >= '2026-10-01'
        AND o.order_date < '2026-11-01'
  );

-- q13
with payments_2026 as(
select payment_method, payment_status, amount
from payments
where payment_date >= '2026-01-01'
and payment_date < '2027-01-01'
)
select payment_method, count(*) as total_payments,
count(*) FILTER (where payment_status = 'successful') as successful,
count(*) FILTER (where payment_status = 'failed') as failed,
count(*) FILTER (where payment_status = 'pending') as pending,
round(100.0 * COUNT(*) FILTER (where payment_status = 'successful'
        ) / NULLIF(COUNT(*), 0),2) as success_rate_pct,
coalesce(SUM(amount) FILTER (where payment_status = 'failed'),0) as failed_amount
from payments_2026
group by payment_method
order by total_payments DESC;

--q14
with category_profit as (
select p.category, sum(oi.line_total) AS revenue,
sum(oi.line_total - (oi.quantity * p.cost_price)) as gross_profit
from orders o
join order_items oi on o.order_id = oi.order_id
join sokomart.products p on oi.product_id = p.product_id
where o.order_status = 'completed'
and o.order_date >= '2025-01-01'
and o.order_date < '2026-01-01'
group by p.category
)
select category, revenue, gross_profit, round(100.0 * gross_profit / NULLIF(revenue, 0),
  2) AS margin_pct,
(select avg(gross_profit)
from category_profit) as avg_category_gross_profit,
round(100.0 * (gross_profit - (select avg(gross_profit) from category_profit)) / NULLIF((
      SELECT AVG(gross_profit) from category_profit
        ), 0),2) as pct_above_avg
from category_profit
where gross_profit > (select avg(gross_profit) from category_profit
)
order by gross_profit DESC;

--q15
with completed_sales as (
select o.order_id, o.shipping_county as county, p.category, oi.line_total
from orders o
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
where o.order_status = 'completed'
and o.order_date >= '2026-01-01'
and o.order_date < '2027-01-01'
and o.shipping_county in (
          'Nairobi',
          'Mombasa',
          'Kisumu',
          'Nakuru',
          'Uasin Gishu'
      ))
SELECT
    CASE
        WHEN GROUPING(county) = 0
         AND GROUPING(category) = 0
            THEN 'county x category'
        WHEN GROUPING(county) = 0
         AND GROUPING(category) = 1
            THEN 'county total'
        WHEN GROUPING(county) = 1
         AND GROUPING(category) = 0
            THEN 'category total'
     ELSE 'grand total'
    END AS grouping_level,
COALESCE(county, 'ALL COUNTIES') AS county,
    COALESCE(category, 'ALL CATEGORIES') AS category,
SUM(line_total) AS revenue,
    COUNT(DISTINCT order_id) AS order_count
FROM completed_sales
GROUP BY GROUPING SETS (
    (county, category),
    (county),
    (category),
    ()
)
ORDER BY
    GROUPING(county),
    county,
    GROUPING(category),
    category;

--q16
CREATE OR REPLACE VIEW sokomart.v_customer_purchase_summary AS
WITH order_totals AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.line_total) AS order_amount
    FROM sokomart.orders o
    JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
    GROUP BY o.order_id, o.customer_id, o.order_date
),
customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) AS completed_orders,
        SUM(order_amount) AS lifetime_spent,
        AVG(order_amount) AS avg_order_value,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM order_totals
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    c.county,
    c.registration_date,
    COALESCE(co.completed_orders, 0) AS completed_orders,
    COALESCE(co.lifetime_spent, 0) AS lifetime_spent,
    COALESCE(co.avg_order_value, 0) AS avg_order_value,
    co.first_order_date,
    co.last_order_date,
    DATE '2026-10-31' - co.last_order_date::DATE
        AS days_since_last_order
FROM sokomart.customers c
LEFT JOIN customer_orders co
    ON c.customer_id = co.customer_id;

--Count all customers and customers with zero completed orders
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (
        WHERE completed_orders = 0
    ) AS customers_with_zero_completed_orders
FROM sokomart.v_customer_purchase_summary;

--Create the monthly category materialized view
DROP MATERIALIZED VIEW IF EXISTS
sokomart.mv_monthly_category_sales;

CREATE MATERIALIZED VIEW sokomart.mv_monthly_category_sales AS
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    p.category,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.line_total) AS revenue,
    SUM(
        oi.line_total - (oi.quantity * p.cost_price)
    ) AS gross_profit
FROM sokomart.orders o
JOIN sokomart.order_items oi
    ON o.order_id = oi.order_id
JOIN sokomart.products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'completed'
GROUP BY
    DATE_TRUNC('month', o.order_date)::DATE,
    p.category;

CREATE UNIQUE INDEX uq_monthly_category_sales
ON sokomart.mv_monthly_category_sales
(sales_month, category);

SELECT *
FROM sokomart.mv_monthly_category_sales
WHERE sales_month = '2025-12-01'
ORDER BY revenue DESC;

--q17
CREATE OR REPLACE FUNCTION sokomart.fn_customer_spend(
    p_customer_id INTEGER,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_spent NUMERIC;
BEGIN
        IF p_end_date < p_start_date THEN
        RAISE EXCEPTION
            'End date (%) cannot be before start date (%)',
            p_end_date, p_start_date;
    END IF;
    SELECT COALESCE(SUM(oi.line_total), 0)
    INTO v_total_spent
    FROM sokomart.orders o
    JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.customer_id = p_customer_id
      AND o.order_status = 'completed'
      AND o.order_date >= p_start_date
      AND o.order_date < p_end_date + INTERVAL '1 day';
    RETURN v_total_spent;
END;
$$;

-- Customer 4000: Full year 2025
SELECT sokomart.fn_customer_spend(
    4000, '2025-01-01', '2025-12-31'
) AS spend_2025;

-- Customer 4000: January to October 2026
SELECT sokomart.fn_customer_spend(
    4000, '2026-01-01', '2026-10-31'
) AS spend_jan_oct_2026;

-- Customer 4000: Entire dataset period
SELECT sokomart.fn_customer_spend(
    4000, '2025-01-01', '2026-10-31'
) AS lifetime_spend;

-- Customer 4000: December 2025
SELECT sokomart.fn_customer_spend(
    4000, '2025-12-01', '2025-12-31'
) AS december_2025_spend;

-- Customer -1: Non-existent customer
SELECT sokomart.fn_customer_spend(
    -1, '2025-01-01', '2025-12-31'
) AS spend_for_nonexistent_customer;

--Comparing function with summary view
SELECT
    customer_id,
    lifetime_spent,
    sokomart.fn_customer_spend(
        customer_id,
        '2025-01-01',
        '2026-10-31'
    ) AS fn_value,
    lifetime_spent = sokomart.fn_customer_spend(
        customer_id,
        '2025-01-01',
        '2026-10-31'
    ) AS matches
FROM sokomart.v_customer_purchase_summary
WHERE customer_id = 4000;

-- Top five Nairobi customers by December 2025 spending
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    sokomart.fn_customer_spend(
        c.customer_id,
        '2025-12-01',
        '2025-12-31'
    ) AS december_2025_spend
FROM sokomart.customers c
WHERE c.county = 'Nairobi'
ORDER BY december_2025_spend DESC
LIMIT 5;

-- Test the invalid date range
SELECT sokomart.fn_customer_spend(
    4000,
    '2026-02-01',
    '2026-01-01'
);

-- q18
CREATE OR REPLACE PROCEDURE sokomart.sp_update_product_price(
    p_product_id INTEGER,
    p_new_price NUMERIC,
    p_reason VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_price NUMERIC;
    v_cost_price NUMERIC;
BEGIN
    SELECT unit_price, cost_price
    INTO v_old_price, v_cost_price
    FROM sokomart.products
    WHERE product_id = p_product_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Product ID % does not exist',
            p_product_id;
    END IF;
    IF p_new_price <= 0 THEN
        RAISE EXCEPTION
            'New price must be greater than zero';
    END IF;
    IF p_new_price < v_cost_price THEN
        RAISE EXCEPTION
            'New price % cannot be below cost price %',
            p_new_price, v_cost_price;
    END IF;
    UPDATE sokomart.products
    SET unit_price = p_new_price
    WHERE product_id = p_product_id;
    INSERT INTO sokomart.product_price_history (
        product_id,
        old_price,
        new_price,
        change_reason
    )
    VALUES (
        p_product_id,
        v_old_price,
        p_new_price,
        p_reason
    );
    INSERT INTO sokomart.audit_logs (
        table_name,
        record_id,
        action,
        old_data,
        new_data
    )
    VALUES (
        'products',
        p_product_id,
        'UPDATE',
        jsonb_build_object('unit_price', v_old_price),
        jsonb_build_object('unit_price', p_new_price)
    );

END;
$$;

-- Show product 71's original price and cost
SELECT
    product_id,
    product_name,
    unit_price,
    cost_price
FROM sokomart.products
WHERE product_id = 71;

-- Change the price to KES 1,099
CALL sokomart.sp_update_product_price(
    71,
    1099.00,
    'Supplier price increase - Nov 2026'
);

-- Prove the new price
SELECT
    product_id,
    product_name,
    unit_price,
    cost_price
FROM sokomart.products
WHERE product_id = 71;

-- Show the price history
SELECT
    price_history_id,
    product_id,
    old_price,
    new_price,
    change_reason
FROM sokomart.product_price_history
WHERE product_id = 71
ORDER BY price_history_id DESC;

-- Show the audit log
SELECT
    table_name,
    record_id,
    action,
    old_data,
    new_data
FROM sokomart.audit_logs
WHERE table_name = 'products'
  AND record_id = 71
ORDER BY audit_id DESC;
select * from audit_logs;

-- Test an invalid price of KES 500
CALL sokomart.sp_update_product_price(
    71,
    500.00,
    'Testing invalid price'
);


-- q19
-- Create the trigger function
CREATE OR REPLACE FUNCTION sokomart.fn_orders_status_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
       INSERT INTO sokomart.order_status_history (
            order_id,
            old_status,
            new_status
        )
        VALUES (
            NEW.order_id,
            NULL,
            NEW.order_status
        );
        INSERT INTO sokomart.audit_logs (
            table_name,
            record_id,
            action,
            old_data,
            new_data
        )
        VALUES (
            'orders',
            NEW.order_id,
            'INSERT',
            NULL,
            jsonb_build_object(
                'order_status', NEW.order_status
            )
        );
    ELSIF TG_OP = 'UPDATE'
       AND OLD.order_status IS DISTINCT FROM NEW.order_status THEN
        INSERT INTO sokomart.order_status_history (
            order_id,
            old_status,
            new_status
        )
        VALUES (
            NEW.order_id,
            OLD.order_status,
            NEW.order_status
        );
        INSERT INTO sokomart.audit_logs (
            table_name,
            record_id,
            action,
            old_data,
            new_data
        )
        VALUES (
            'orders',
            NEW.order_id,
            'UPDATE',
            jsonb_build_object(
                'order_status', OLD.order_status
            ),
            jsonb_build_object(
                'order_status', NEW.order_status
            )
        );

    END IF;
    RETURN NEW;
END;
$$;

-- Create the trigger
DROP TRIGGER IF EXISTS trg_orders_status_audit
ON sokomart.orders;

CREATE TRIGGER trg_orders_status_audit
AFTER INSERT OR UPDATE OF order_status
ON sokomart.orders
FOR EACH ROW
EXECUTE FUNCTION sokomart.fn_orders_status_audit();

-- Create the order status procedure
CREATE OR REPLACE PROCEDURE sokomart.sp_update_order_status(
    p_order_id INTEGER,
    p_new_status VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR;
BEGIN
    -- Lock the order while changing its status
    SELECT order_status
    INTO v_current_status
    FROM sokomart.orders
    WHERE order_id = p_order_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Order ID % does not exist',
            p_order_id;
    END IF;
    IF NOT (
        (v_current_status = 'pending'
            AND p_new_status IN ('completed', 'cancelled'))
        OR
        (v_current_status = 'completed'
            AND p_new_status = 'returned')
    ) THEN
        RAISE EXCEPTION
            'Invalid status transition: % to % for order %',
            v_current_status,
            p_new_status,
            p_order_id;
    END IF;
    UPDATE sokomart.orders
    SET order_status = p_new_status
    WHERE order_id = p_order_id;
    IF p_new_status = 'completed' THEN
        UPDATE sokomart.payments
        SET payment_status = 'successful'
        WHERE order_id = p_order_id;
    ELSIF p_new_status = 'cancelled' THEN
        UPDATE sokomart.payments
        SET payment_status = 'failed'
        WHERE order_id = p_order_id
          AND payment_status = 'pending';
    END IF;
END;
$$;

-- Test using order 48882
    -- Check the original order and payment status.
SELECT
    o.order_id,
    o.order_status,
    p.payment_status
FROM sokomart.orders o
JOIN sokomart.payments p
    ON o.order_id = p.order_id
WHERE o.order_id = 48882;


-- Complete the order.
CALL sokomart.sp_update_order_status(
    48882,
    'completed'
);


-- Confirm the order and payment statuses changed.
SELECT
    o.order_id,
    o.order_status,
    p.payment_status
FROM sokomart.orders o
JOIN sokomart.payments p
    ON o.order_id = p.order_id
WHERE o.order_id = 48882;
-- order status completed and payment status successful.

-- Show the status history.
SELECT
    order_id,
    old_status,
    new_status
FROM sokomart.order_status_history
WHERE order_id = 48882
ORDER BY status_history_id;

--. Show the audit log.
SELECT
    table_name,
    record_id,
    action,
    old_data,
    new_data
FROM sokomart.audit_logs
WHERE table_name = 'orders'
  AND record_id = 48882
ORDER BY audit_id;
select * from audit_logs;


-- Use a plain UPDATE to change the order to returned.
UPDATE sokomart.orders
SET order_status = 'returned'
WHERE order_id = 48882;


-- Check the history:
SELECT
    order_id,
    old_status,
    new_status
FROM sokomart.order_status_history
WHERE order_id = 48882
ORDER BY status_history_id;
/*You should now see two status history rows:
- pending → completed
- completed → returned
*/

-- Update shipping county without changing the status.
UPDATE sokomart.orders
SET shipping_county = shipping_county
WHERE order_id = 48882;

--Check the history count:
SELECT COUNT(*) AS history_rows
FROM sokomart.order_status_history
WHERE order_id = 48882;

--Expected: 2. The trigger does not add another row because the status did not change.

-- Test an invalid transition.
CALL sokomart.sp_update_order_status(
    49961,
    'completed'
);

-- q20
CREATE OR REPLACE PROCEDURE sokomart.sp_place_order(
    p_customer_id INTEGER,
    p_product_ids INTEGER[],
    p_quantities INTEGER[],
    p_payment_method VARCHAR,
    INOUT p_order_id INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_county VARCHAR;
    v_customer_status VARCHAR;
    v_product_id INTEGER;
    v_quantity INTEGER;
    v_available INTEGER;
    v_price NUMERIC;
    v_items_total NUMERIC := 0;
    v_delivery_fee NUMERIC := 0;
    v_total_amount NUMERIC := 0;
    v_transaction_reference VARCHAR;
    i INTEGER;
BEGIN
      SELECT county, customer_status
    INTO v_customer_county, v_customer_status
    FROM sokomart.customers
    WHERE customer_id = p_customer_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Customer ID % does not exist',
            p_customer_id;
    END IF;
    IF v_customer_status <> 'active' THEN
        RAISE EXCEPTION
            'Customer ID % is not active',
            p_customer_id;
    END IF;
    IF p_product_ids IS NULL OR p_quantities IS NULL THEN
        RAISE EXCEPTION
            'Product IDs and quantities cannot be NULL';
    END IF;
    IF COALESCE(array_length(p_product_ids, 1), 0)
       <> COALESCE(array_length(p_quantities, 1), 0) THEN
        RAISE EXCEPTION
            'Product IDs and quantities must have the same length';
    END IF;
    IF COALESCE(array_length(p_product_ids, 1), 0) = 0 THEN
        RAISE EXCEPTION
            'At least one product is required';
    END IF;
    INSERT INTO sokomart.orders (
        customer_id,
        order_date,
        order_status,
        shipping_county,
        delivery_fee,
        total_amount
    )
    VALUES (
        p_customer_id,
        CURRENT_DATE,
        'pending',
        v_customer_county,
        0,
        0
    )
    RETURNING order_id INTO p_order_id;
    FOR i IN 1..array_length(p_product_ids, 1)
    LOOP
        v_product_id := p_product_ids[i];
        v_quantity := p_quantities[i];

        IF v_quantity IS NULL OR v_quantity <= 0 THEN
            RAISE EXCEPTION
                'Invalid quantity % for product %',
                v_quantity, v_product_id;
        END IF;
        UPDATE sokomart.products
        SET stock_quantity = stock_quantity - v_quantity
        WHERE product_id = v_product_id
          AND stock_quantity >= v_quantity
          AND product_status = 'active'
        RETURNING unit_price INTO v_price;
        IF NOT FOUND THEN
            SELECT stock_quantity
            INTO v_available
            FROM sokomart.products
            WHERE product_id = v_product_id;
            IF NOT FOUND THEN
                RAISE EXCEPTION
                    'Product % does not exist',
                    v_product_id;
            END IF;
            RAISE EXCEPTION
                'Insufficient stock or inactive product %. Requested: %, available: %',
                v_product_id,
                v_quantity,
                v_available;
        END IF;
        v_items_total := v_items_total + (v_quantity * v_price);
        INSERT INTO sokomart.order_items (
            order_id,
            product_id,
            quantity,
            unit_price,
            line_total
        )
        VALUES (
            p_order_id,
            v_product_id,
            v_quantity,
            v_price,
            v_quantity * v_price
        );

    END LOOP;
    IF v_items_total >= 5000 THEN
        v_delivery_fee := 0;
    ELSIF v_customer_county = 'Nairobi' THEN
        v_delivery_fee := 200;
    ELSIF v_customer_county IN (
        'Kiambu',
        'Kajiado',
        'Machakos'
    ) THEN
        v_delivery_fee := 250;
    ELSE
        v_delivery_fee := 350;
    END IF;
    v_total_amount := v_items_total + v_delivery_fee;
    UPDATE sokomart.orders
    SET
        delivery_fee = v_delivery_fee,
        total_amount = v_total_amount
    WHERE order_id = p_order_id;
    IF LOWER(REPLACE(p_payment_method, ' ', '_'))
       NOT IN ('cash_on_delivery', 'cashondelivery') THEN
           v_transaction_reference :=
    LEFT(REPLACE(gen_random_uuid()::TEXT, '-', ''), 30);
    ELSE
        v_transaction_reference := NULL;
    END IF;
    INSERT INTO sokomart.payments (
        order_id,
        payment_method,
        amount,
        payment_status,
        transaction_reference
    )
    VALUES (
        p_order_id,
        p_payment_method,
        v_total_amount,
        'pending',
        v_transaction_reference
    );
END;
$$;

--Test successful order placement
-- Show the original prices and stock levels.
SELECT
    product_id,
    product_name,
    unit_price,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (6, 73, 82)
ORDER BY product_id;


-- Place the order.
CALL sokomart.sp_place_order(
    177,
    ARRAY[6, 73, 82],
    ARRAY[1, 2, 3],
    'M-Pesa',
    NULL
);

-- Show the order and its items total.
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.shipping_county,
    o.delivery_fee,
    o.total_amount,
    COALESCE(SUM(oi.line_total), 0) AS items_total
FROM sokomart.orders o
LEFT JOIN sokomart.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_id = 50006
GROUP BY
    o.order_id,
    o.customer_id,
    o.order_status,
    o.shipping_county,
    o.delivery_fee,
    o.total_amount;

Show the order lines.
SELECT
    order_id,
    product_id,
    quantity,
    unit_price,
    line_total
FROM sokomart.order_items
WHERE order_id = <YOUR_NEW_ORDER_ID>;


-- Show the payment.
SELECT
    order_id,
    payment_method,
    amount,
    payment_status,
    transaction_reference IS NOT NULL AS has_reference
FROM sokomart.payments
WHERE order_id = 50006;

--Show the updated stock.
SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (6, 73, 82)
ORDER BY product_id;


--Show the order status history created by the Q19 trigger.
SELECT
    order_id,
    old_status,
    new_status
FROM sokomart.order_status_history
WHERE order_id = 50006;

-- Test insufficient stock and atomic rollback
      -- Check the current order count and stock.
SELECT COUNT(*) AS total_orders
FROM sokomart.orders;

SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (6, 59)
ORDER BY product_id;


-- Attempt to place an order.
CALL sokomart.sp_place_order(
    408,
    ARRAY[6, 59],
    ARRAY[1, 2],
    'card',
    NULL
);

-- Product 59 has only one unit available, but the procedure requests two. The call should raise an exception.

-- Check the order count and stock again.
SELECT COUNT(*) AS total_orders
FROM sokomart.orders;

SELECT
    product_id,
    product_name,
    stock_quantity
FROM sokomart.products
WHERE product_id IN (6, 59)
ORDER BY product_id;

-- Complete the new order and refresh the materialized view
--Use the order ID returned from the successful call in Part B.

-- Complete the order.
CALL sokomart.sp_update_order_status(
    50006,
    'completed'
);

-- The Q19 procedure updates the payment status to successful, and the Q19 trigger records the status change.

-- Refresh the materialized view.
REFRESH MATERIALIZED VIEW CONCURRENTLY
sokomart.mv_monthly_category_sales;

-- CONCURRENTLY allows readers to continue querying the materialized view while it refreshes. It requires the unique index created in Q16.

-- Show the November 2026 sales.
SELECT
    sales_month,
    category,
    orders,
    units_sold,
    revenue,
    gross_profit
FROM sokomart.mv_monthly_category_sales
WHERE sales_month >= '2026-11-01' and sales_month<= '2026-11-30'
ORDER BY revenue DESC;




