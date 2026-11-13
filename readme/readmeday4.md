# Day 4: Query Optimization, Transactions and Data Quality

## Project Overview

This section of the LuxDevHQ Cohort 9 Advanced SQL project focuses on query performance, database transactions, data cleaning and customer purchasing behaviour using PostgreSQL.

The exercises use the SokoMart Kenya database to explore how SQL can improve query efficiency, maintain data integrity and generate useful business insights.

## Database

- **Database:** `luxdevhq_cohort9_advanced_sql`
- **Schema:** `sokomart`
- **DBMS:** PostgreSQL

## Topics Covered

### Question 21: Query Execution Plans

Used `EXPLAIN (ANALYZE, BUFFERS)` to examine the execution plan of a query retrieving completed orders from Kisumu in September 2026.

Analysed:
- Query execution time.
- Planning time.
- Estimated versus actual rows.
- Scan methods.
- Join methods.
- Buffer usage.

**Recorded findings:**
- Actual result rows: 91.
- Planning time: 21.210 ms.
- Execution time: 3.875 ms.
- Orders table used an index scan on `idx_orders_order_date`.
- The execution plan included hash joins and nested loops.

### Question 22: Indexing and Query Optimization

Compared query execution plans before and after index creation.

Worked with:
- Customer order lookups.
- Payment lookups.
- Product order-item lookups.
- Partial indexes.

Created a partial index:

`idx_orders_pending_date`

This index covers pending orders and their order dates.

**Recorded findings:**
- Customer order lookup: 0.104 ms before and 0.071 ms after.
- Payment lookup: 1.834 ms before and 0.018 ms after.
- Product order-item lookup: 0.547 ms before and 0.465 ms after.
- Partial pending-orders index size: 32 kB.
- Full order-date index size: 1,112 kB.
- The partial index was approximately 97.1% smaller.

**Note:** The earlier comparison plans used existing indexes. Therefore, these timings represent a comparison between the recorded earlier and later plans, not a verified index-free versus indexed comparison.

### Question 23: Transaction Management

Practised transaction control using:

- `BEGIN`
- `COMMIT`
- `ROLLBACK`
- `SAVEPOINT`
- `ROLLBACK TO SAVEPOINT`

The exercises involved:
- Applying a temporary discount to Beauty products and rolling back the changes.
- Restocking a product while using a savepoint to undo a subsequent operation.
- Testing how PostgreSQL handles constraint violations within a transaction.

### Question 24: Removing Duplicate Payment Records

Worked with the `payment_staging` table to identify and remove duplicate payment records.

Applied:
- `GROUP BY` and `HAVING COUNT(*)` to identify duplicates.
- `ROW_NUMBER()` to rank duplicate records.
- Common Table Expressions (CTEs) to organise the cleaning process.
- `DELETE` with a CTE to remove extra records.
- A unique index to prevent duplicate payment IDs.

The staging table contains the following columns:

- `payment_id`
- `staging_id`
- `order_id`
- `payment_date`
- `payment_method`

The record with the smallest `staging_id` was retained for each `payment_id`.

### Question 25: Consecutive Monthly Customer Purchases

Applied the gaps-and-islands technique to identify customers who made completed purchases for at least three consecutive months.

SQL concepts used:
- `DATE_TRUNC()`
- `DISTINCT`
- `ROW_NUMBER()`
- `PARTITION BY`
- `GROUP BY`
- `HAVING`
- Common Table Expressions (CTEs)

The query identifies each customer's longest qualifying purchase streak and ranks the top 10 customers.

## Key Learning Outcomes

By completing Day 4, I gained practical experience in:

- Reading and interpreting PostgreSQL execution plans.
- Measuring query performance using `EXPLAIN ANALYZE`.
- Understanding index scans, bitmap scans and join methods.
- Creating and evaluating partial indexes.
- Managing transactions and savepoints.
- Identifying and removing duplicate records.
- Using unique indexes to enforce data integrity.
- Applying window functions to analyse customer purchasing patterns.
- Using gaps-and-islands analysis to identify consecutive monthly activity.

## How to Run

1. Open DBeaver or another PostgreSQL client.
2. Connect to `luxdevhq_cohort9_advanced_sql`.
3. Ensure the `sokomart` schema is available.
4. Navigate to the Day 4 SQL scripts.
5. Execute the scripts in question order, from Q21 to Q25.
6. Review the execution plans and query outputs.
7. Record the actual results obtained from the database.

## Conclusion

Day 4 provided practical experience in database performance optimization, transaction management, data cleaning and customer behaviour analysis.

The exercises demonstrated how PostgreSQL can be used not only to retrieve information but also to improve database performance, protect data integrity and generate insights that support business decisions.
