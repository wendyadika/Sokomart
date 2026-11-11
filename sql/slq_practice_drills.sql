select * from customers;
select * from orders;
select * from audit_logs;
select * from order_items;
select * from payment_staging;
select * from payments;
select * from product_price_history;
select * from products;
select * from order_status_history;

/*D1	List the products whose unit_price is above the average unit_price of all products. Show the 10 most expensive, 
then on a second query the count.
*/

select product_id, product_name, category, unit_price, avg(unit_price) as avg_price
from products 
where unit_price > (select avg(unit_price) from products)
group by product_id, product_name, category
order by avg(unit_price) desc
limit 10;

select count(*) as total_products_above_avg from products
where unit_price > (select avg(unit_price) from products);

-- D2 List customers living in Mombasa who placed at least one order (any status) in December 2025.
select customer_id, first_name, last_name, email
from customers 
where county = 'Mombasa'
and customer_id in (select customer_id from orders where order_date >= '2025-12-01' and order_date <= '2025-12-31');

select count(*) as total_Mombasa_customers_dec2025
from customers
where county = 'Mombasa'
and customer_id in (select customer_id from orders where order_date >= '2025-12-01' and order_date <= '2025-12-31');

-- D3	How many customers living in Kisumu have at least one payment with payment_status = 'failed'?
select count(*) as customerskisumu_failed_payment
from sokomart.customers c
where c.county = 'Kisumu'
and exists (
    select 1
    from sokomart.orders o
    join sokomart.payments p on o.order_id = p.order_id
    where o.customer_id = c.customer_id and p.payment_status = 'failed');

/*D4	For each order_status, show the number of orders, 
the average number of lines per order and the average number of units per order.
Compute the per-order figures in a subquery in FROM.
*/

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

select order_status, count(*) as total_orders, avg(line_count) as avg_lines_per_order,
avg(unit_count) as avg_units_per_order
from (
select o.order_id, o.order_status, count(oi.order_item_id) as line_count,
sum(oi.quantity) as unit_count
from orders o
left join order_items oi on o.order_id = oi.order_id
group by o.order_id, o.order_status
) as order_summary
group by order_status;

/*D5	Top 5 shipping counties by number of completed orders in 2026. 
Put the filtered orders in a CTE.	Single CTE	shipping_county, completed_orders
*/
select * from customers;
select * from orders;
select * from audit_logs;
select * from order_items;
select * from payment_staging;
select * from payments;
select * from product_price_history;
select * from products;
select * from order_status_history;

with shipping_counties_summary_2026 as (
select order_id, shipping_county
from orders 
where order_status = 'completed'
and  order_date >= '2026-01-01' and order_date < '2027-01-01'
)
select shipping_county, count(*) as completed_orders
from shipping_counties_summary_2026
group by shipping_county 
order by completed_orders desc
limit 5;

/*D6	For 2025: completed orders per month, the 2025 monthly average, 
 and whether each month is above average or at/below average. 
 Use two CTEs (monthly counts, then the stats).	
 Chained CTEs	month, completed_orders, avg_per_month, vs_average (12 rows)
 */
with monthly_counts as (
select date_trunc('month', order_date) as month,
count(*) as completed_orders
from orders
where order_status = 'completed'
and order_date >= '2025-01-01'
and order_date < '2026-01-01'
group by date_trunc('month', order_date)
),
monthly_stats as (
select avg(completed_orders) as avg_per_month
from monthly_counts
)
select TO_CHAR(mc.month, 'YYYY-MM') AS month, mc.completed_orders,
round(ms.avg_per_month, 2) AS avg_per_month,
case
    when mc.completed_orders > ms.avg_per_month
         then 'above average'
        else 'at/below average'
    end as vs_average
from monthly_counts mc
cross join monthly_stats ms
order by mc.month;

/*D7 Write sokomart.fn_order_count(p_customer_id INTEGER) RETURNS INTEGER 
— the number of orders (any status) a customer has. 
Call it for customer 177 and for a customer that does not exist (-1).	
SQL function	two numbers
*/
create or replace function fn_order_count(p_customer_id int)
returns int
language sql
as $$
  select count(*) :: integer from orders 
    where customer_id = p_customer_id;
$$;

select fn_order_count(177);
select fn_order_count(-1);


/*D8	Write sokomart.sp_set_customer_status(p_customer_id INTEGER, p_status VARCHAR).
 It raises an exception for a status other than active / inactive / suspended, and 
 for a customer that does not exist. 
 Inside BEGIN … ROLLBACK, set customer 177 to suspended, show it, roll back, 
 show it is active again. \
 Then show the exception for status 'vip'.	
 Stored procedure, RAISE EXCEPTION,
 CALL	the three status checks + the error message
 */


create or replace procedure sokomart.sp_set_customer_status(
    p_customer_id Int,
    p_customer_status varchar
)
language plpgsql
as $$
begin
    if p_customer_status is null or
       p_customer_status not in ('active', 'inactive', 'suspended') then
       raise exception
            'Invalid customer status: %. Allowed statuses are active, inactive, suspended.',
            p_customer_status;
end if;

    if not exists (
        select 1
        from sokomart.customers
        where customer_id = p_customer_id
    ) then

        raise exception
            'Customer ID % does not exist.',
            p_customer_id;

    end if;

    update sokomart.customers
    set customer_status = p_customer_status
    where customer_id = p_customer_id;

end;
$$;

select customer_id, customer_status
FROM customers
WHERE customer_id = 177;

begin;
call sokomart.sp_set_customer_status(177, 'suspended');

select customer_id, customer_status
from customers
where customer_id = 177;
rollback;

call sokomart.sp_set_customer_status(177, 'vip');

/*D9	Beauty products whose stock_quantity is below the average Beauty stock. 
 Put the Beauty products in a CTE and compare with a scalar subquery on that CTE.	
 CTE + scalar subquery	product_id, product_name, stock_quantity, beauty_avg_stock
 */
with beauty_products as(
select product_id, product_name, stock_quantity
from products 
where category = 'Beauty'
)
select product_id, product_name, stock_quantity, (select avg(stock_quantity)as beauty_avg_stock from beauty_products)
from beauty_products
where stock_quantity < (select avg(stock_quantity) from beauty_products);



/*D10	Write sokomart.sp_county_summary(IN p_county VARCHAR, OUT p_customers INTEGER, 
OUT p_revenue NUMERIC) returning the number of customers living in the county 
and their completed revenue. CALL sokomart.sp_county_summary('Nakuru', NULL, NULL);	
Procedure with OUT parameters p_customers, p_revenue (one row)
*/
create or replace procedure sokomart.sp_county_summary(in p_county varchar,
out p_customers int, out p_revenue numeric)
language plpgsql
as $$
begin
    select count(*)::integer
    into p_customers
    from sokomart.customers
    where county = p_county;

    select COALESCE(sum(oi.line_total), 0)
    INTO p_revenue
    from sokomart.customers c
    join sokomart.orders o on c.customer_id = o.customer_id
    join sokomart.order_items oi on o.order_id = oi.order_id
    where c.county = p_county and o.order_status = 'completed';

end;
$$;

call sokomart.sp_county_summary('Nakuru',NULL, NULL);


