set search_path to sokomart;
select * from customers;
select * from order_items;
select * from orders;
select * from payments;
select * from products;
select * from order_status_history;

-- Q6
with customer_totals as (
select c.customer_id, c.county, c.first_name || ' ' || c.last_name as full_name,
sum(oi.line_total) as total_revenue
from customers c
join orders o on c.customer_id = o.customer_id
join order_items oi on o.order_id = oi.order_id
where o.order_status = 'completed'
group by c.customer_id, c.county, c.first_name, c.last_name
),
county_rankings as (
select county, DENSE_RANK() OVER ( PARTITION BY county ORDER BY total_revenue DESC) as county_rank,
customer_id, full_name, total_revenue
from customer_totals
)
select county, county_rank, customer_id, full_name, total_revenue
from county_rankings
where county_rank <= 3
order by county, county_rank, customer_id;

-- q7
with product_sales as (
select p.product_id, p.product_name, p.category, SUM(oi.line_total) as revenue,
sum(oi.quantity) as units_sold
from products p
join order_items oi on p.product_id = oi.product_id
join orders o on oi.order_id = o.order_id
where o.order_status = 'completed'
and o.order_date >= '2025-01-01'
and o.order_date < '2026-01-01'
group by p.product_id, p.product_name, p.category
),
product_rankings as (
select category, ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC, product_id) as rank_in_category,
product_id, product_name, revenue, units_sold
from product_sales
)
select category, rank_in_category, product_id, product_name, revenue, units_sold
from product_rankings
where rank_in_category <= 3
order by category, rank_in_category;

-- q8
with all_months as (
select GENERATE_SERIES('2025-01-01'::DATE, '2026-10-01'::DATE, INTERVAL '1 month')::DATE AS month
),
monthly_revenue as(
select date_trunc('month', o.order_date)::DATE as month, sum(oi.line_total) as revenue
from orders o
join order_items oi on o.order_id = oi.order_id
where o.order_status = 'completed'
and o.order_date >= '2025-01-01'
and o.order_date < '2026-11-01'
group by date_trunc('month', o.order_date)::DATE
),
monthly_data as (
select am.month, cOALESCE(mr.revenue, 0) as revenue
from all_months am
left join monthly_revenue mr on am.month = mr.month
),
revenue_comparison as (
select month, revenue, LAG(revenue) OVER (ORDER BY month) as prev_month_revenue
from monthly_data
)
select TO_CHAR(month, 'YYYY-MM') as month, revenue, prev_month_revenue, 
ROUND(100.0 * (revenue - prev_month_revenue)/ NULLIF(prev_month_revenue, 0),2) as growth_pct
from revenue_comparison
ORDER BY month;

--q9
with customer_orders as (
select c.customer_id, o.order_id, o.order_date, o.total_amount
from customers c
join orders o on c.customer_id = o.customer_id
where c.county = 'Nyeri'
and o.order_status = 'completed'
and o.order_date >= '2026-01-01'
and o.order_date < '2027-01-01'
),
order_comparison as (
select customer_id, order_id, order_date, total_amount, LAG(total_amount) OVER (
PARTITION BY customer_id ORDER BY order_date, order_id) AS previous_order_amount
from customer_orders
),
order_analysis as (
select customer_id, order_id, order_date, total_amount, previous_order_amount,
 total_amount - previous_order_amount as change_amount,
case
    when previous_order_amount IS NULL THEN 'first order'
    when total_amount > previous_order_amount THEN 'up'
    when total_amount < previous_order_amount THEN 'down'
    else 'same'
        end as direction
    from order_comparison
)
select customer_id, order_id, order_date, total_amount, previous_order_amount,
    change_amount, direction
from order_analysis
order by customer_id, order_date, order_id;

--summary query 
select
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customers,

    COUNT(*) FILTER (
        WHERE direction = 'first order'
    ) AS first_orders,

    COUNT(*) FILTER (
        WHERE direction = 'up'
    ) AS orders_bigger_than_previous,

    COUNT(*) FILTER (
        WHERE direction = 'down'
    ) AS orders_smaller_than_previous

FROM order_analysis;

-- Q10
with all_months as (
select GENERATE_SERIES('2025-01-01'::DATE, '2026-10-01'::DATE, INTERVAL '1 month')::DATE AS month
),
monthly_revenue as (
select DATE_TRUNC('month', o.order_date)::DATE AS month, SUM(oi.line_total) AS monthly_revenue
from orders o
join order_items oi on o.order_id = oi.order_id
where o.order_status = 'completed'
and o.order_date >= '2025-01-01'
and o.order_date < '2026-11-01'
group by DATE_TRUNC('month', o.order_date)::DATE
),
monthly_data as (
select EXTRACT(YEAR FROM am.month)::INTEGER as year, am.month,
        COALESCE(mr.monthly_revenue, 0) as monthly_revenue
from all_months am
left join monthly_revenue mr on am.month = mr.month
)
select year, TO_CHAR(month, 'YYYY-MM') AS month, monthly_revenue,
sum(monthly_revenue) OVER (PARTITION BY year ORDER BY month
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_revenue_ytd,
sum(monthly_revenue) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
 ) as running_revenue_all_time
from monthly_data
order by month;
