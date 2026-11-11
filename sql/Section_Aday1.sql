set search_path to sokomart;
select * from customers;
select * from orders;
select * from audit_logs;
select * from order_items;
select * from payment_staging;
select * from payments;
select * from product_price_history;
select * from products;
select * from order_status_history;

--q1. 
with customer_revenue as (
    select o.customer_id, sum(oi.line_total) as total_spent_2025
    from sokomart.orders o
    join sokomart.order_items oi on o.order_id = oi.order_id
    where o.order_status = 'completed'
     and o.order_date >= '2025-01-01'
     and o.order_date < '2026-01-01'
    GROUP BY o.customer_id
)
select c.customer_id, c.first_name || ' ' || c.last_name AS full_name, c.county,
cr.total_spent_2025, 
(select avg(total_spent_2025) from customer_revenue) as avg_spent_2025,
cr.total_spent_2025 - (select avg(total_spent_2025) from customer_revenue) as amount_above_avg
from customer_revenue cr
join customers c on cr.customer_id = c.customer_id
where cr.total_spent_2025 > (select avg(total_spent_2025) from customer_revenue
)
order by total_spent_2025 DESC;

-- Q2
select p.product_id, p.product_name, p.category, p.unit_price,
(select round(avg(p2.unit_price),2) from sokomart.products p2 where p2.category = p.category) as category_avg_price,
p.unit_price - (select avg(p2.unit_price) from sokomart.products p2 where p2.category = p.category
    ) as price_gap
from sokomart.products p
where p.product_status = 'active'
and p.unit_price > (select avg(p2.unit_price)
from sokomart.products p2
where p2.category = p.category
)
order by p.category, price_gap DESC;

select category, count(*) AS premium_product_count
from (
select p.product_id, p.category, p.unit_price
from sokomart.products p
where p.product_status = 'active'
and p.unit_price > (select avg(p2.unit_price) from sokomart.products p2
where p2.category = p.category)
) as premium_products
group by category
order by premium_product_count DESC;

--Q3
with completed_order_lines as (
select date_trunc('month', o.order_date)::date as month,
oi.line_total as revenue,
oi.quantity * p.cost_price as line_cost
from sokomart.orders o
join sokomart.order_items oi on o.order_id = oi.order_id
join sokomart.products p on oi.product_id = p.product_id
where o.order_status = 'completed'
and o.order_date >= '2026-01-01'
and o.order_date < '2026-11-01'
),
monthly_totals as (
 select month, sum(revenue) as revenue, SUM(line_cost) as cost
    from completed_order_lines
    group by month
),
monthly_profit as (
  select month, revenue, cost, revenue - cost as gross_profit
    FROM monthly_totals
),
all_months as (
 select generate_series(
            '2026-01-01'::DATE,
            '2026-10-01'::DATE,
            interval '1 month'
        )::DATE as month
)
select TO_CHAR(am.month, 'YYYY-MM') as month, COALESCE(mp.revenue, 0) as revenue,
    COALESCE(mp.cost, 0) as cost, COALESCE(mp.gross_profit, 0) as gross_profit,
    case
        when COALESCE(mp.revenue, 0) = 0 THEN NULL
        else  ROUND(100.0 * mp.gross_profit / NULLIF(mp.revenue, 0),2)
    end as margin_pct
from all_months am
left join monthly_profit mp on am.month = mp.month
order by am.month;

-- Q4
select c.customer_id, c.first_name || ' ' || c.last_name AS full_name, c.county,
customer_summary.category_count, customer_summary.total_spent
from sokomart.customers c
join (select o.customer_id, COUNT(DISTINCT p.category) AS category_count,
      SUM(oi.line_total) AS total_spent
    from sokomart.orders o
    join sokomart.order_items oi on o.order_id = oi.order_id
    join sokomart.products p on oi.product_id = p.product_id
    where o.order_status = 'completed'
    group by o.customer_id
) as customer_summary
  on c.customer_id = customer_summary.customer_id
where c.county = 'Nakuru' and customer_summary.category_count >= 3
order by customer_summary.category_count DESC,
    customer_summary.total_spent DESC;

select count(*) AS qualifying_customers, count(*) filter (where customer_summary.category_count = 5
    ) as customers_who_bought_all_five_categories
from sokomart.customers c
join (
    select
        o.customer_id,
        COUNT(DISTINCT p.category) as category_count,
        SUM(oi.line_total) as total_spent
    FROM sokomart.orders o
    join sokomart.order_items oi on o.order_id = oi.order_id
    join sokomart.products p on oi.product_id = p.product_id
    where o.order_status = 'completed'
    group by  o.customer_id
) as customer_summary
    on c.customer_id = customer_summary.customer_id
where c.county = 'Nakuru' and customer_summary.category_count >= 3;

-- q5
select p.product_id, p.product_name, p.category, p.product_status, p.stock_quantity,
    p.created_at
from sokomart.products p
where NOT EXISTS (
    SELECT 1
    from sokomart.order_items oi
    where oi.product_id = p.product_id
)
order by p.category, p.product_name;