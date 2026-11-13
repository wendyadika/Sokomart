# LuxDevHQ Cohort 9 – Advanced SQL Practical Project
## Day 3: Advanced PostgreSQL Programming

### Project Overview
Day 3 focused on applying advanced PostgreSQL concepts to the SokoMart Kenya retail database. The exercises involved building reusable database objects, automating business processes, maintaining audit records, and managing transactions.

The project was implemented using PostgreSQL and DBeaver.

### Database Information
- **Database:** `luxdevhq_cohort9_advanced_sql`
- **Schema:** `sokomart`
- **SQL Language:** PostgreSQL / PL/pgSQL
- **Tool:** DBeaver

---

### Tasks Completed

#### Q16: Views and Materialized Views
Created database views to simplify reporting and improve access to summarized business information.

**a) Customer Purchase Summary View**
- Created `sokomart.v_customer_purchase_summary`.
- Summarized customer purchasing activity.
- Calculated completed orders, lifetime spending, average order value, first order date, and last order date.
- Included customers with no completed orders using `LEFT JOIN`.
- Calculated the number of days since the customer's last purchase.

**b) Monthly Category Sales Materialized View**
- Created `sokomart.mv_monthly_category_sales`.
- Summarized monthly sales performance by product category.
- Calculated completed orders, units sold, revenue, and gross profit.
- Created a unique index to support concurrent materialized view refreshes.
- Refreshed the materialized view after new transactions.

**Concepts learned:** Views, materialized views, CTEs, aggregation, indexes, and `REFRESH MATERIALIZED VIEW`.

#### Q17: User-Defined Functions
Created `sokomart.fn_customer_spend()` to calculate the total amount spent by a customer within a specified date range.

The function:
- Accepts a customer ID, start date, and end date.
- Calculates spending from completed orders only.
- Returns zero when a customer has no qualifying purchases.
- Raises an exception when the end date is earlier than the start date.

Tested the function using different date ranges and customer IDs and compared its results with the customer purchase summary view.

**Concepts learned:** PL/pgSQL functions, parameters, return values, date filtering, `COALESCE`, and exception handling.

#### Q18: Stored Procedures and Audit Logging
Created `sokomart.sp_update_product_price()` to manage product price changes.

The procedure:
- Accepts a product ID, new price, and reason for the change.
- Checks whether the product exists.
- Validates that the new price is positive and not below the product's cost price.
- Locks the product record during the update.
- Updates the product price.
- Records the previous and new prices in the price history table.
- Creates an audit log recording the change.

Tested successful price updates and invalid product IDs.

**Concepts learned:** Stored procedures, transaction control, row locking, validation, price history, and audit logging.

#### Q19: Triggers and Order Status Management
Created a trigger function and stored procedure to manage order status changes.

Implemented:
- `sokomart.fn_orders_status_audit()` to record order status changes.
- `trg_orders_status_audit` to automatically capture relevant order inserts and status updates.
- `sokomart.sp_update_order_status()` to validate and process order status transitions.

The procedure enforced business rules:
- Pending orders can become completed or cancelled.
- Completed orders can become returned.
- An order can only be completed when its payment is successful.
- Pending payments are marked failed when an order is cancelled.

Tested valid transitions, invalid transitions, and updates that do not change the order status.

**Concepts learned:** Trigger functions, `OLD` and `NEW` records, `TG_OP`, `IS DISTINCT FROM`, stored procedures, and automated audit trails.

#### Q20: Transactional Order Processing
Created `sokomart.sp_place_order()` to automate the order placement process.

The procedure:
- Validates that the customer exists and is active.
- Checks that product IDs and quantities are supplied in matching, non-empty arrays.
- Creates a pending order.
- Checks product availability and active status.
- Reduces stock quantities when products are available.
- Creates order item records using current product prices.
- Calculates the order subtotal and delivery fee.
- Applies the delivery fee rules based on order value and customer location.
- Creates a pending payment record.
- Generates a transaction reference for applicable payment methods.

Tested successful order placement and an unsuccessful order where a product had insufficient stock. The failed transaction was expected to roll back without leaving partial order records or stock deductions.

Also tested completing a newly placed order and refreshing the monthly category sales materialized view.

**Concepts learned:** PL/pgSQL procedures, arrays, loops, conditional updates, `RETURNING`, exception handling, atomic transactions, stock management, and business rule implementation.

---

### Key SQL Concepts Practised

| Concept | Application |
|---|---|
| Views | Reusable customer purchase summaries |
| Materialized Views | Stored monthly sales summaries |
| Functions | Customer spending calculations |
| Stored Procedures | Product price updates and order processing |
| Triggers | Automatic order status auditing |
| CTEs | Organizing complex queries |
| Indexes | Supporting materialized view refreshes |
| Exception Handling | Managing invalid operations |
| Row Locking | Protecting records during updates |
| Transactions | Ensuring reliable order placement |
| Aggregation | Calculating revenue, profit, and spending |

### Key Learning Outcomes
By completing Day 3, I strengthened my ability to:
1. Create reusable database objects for reporting and analysis.
2. Develop PostgreSQL functions with parameters and return values.
3. Implement stored procedures that enforce business rules.
4. Automate database auditing using triggers.
5. Apply validation and exception handling in database operations.
6. Use transactions to maintain data consistency.
7. Build practical order processing and inventory management workflows.

### Conclusion
Day 3 provided practical experience in advanced PostgreSQL programming. The exercises demonstrated how database objects can automate business operations, improve data integrity, support reporting, and maintain accurate records in a retail management system.


