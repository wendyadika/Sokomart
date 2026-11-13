## DAY 2 – Window Functions

### Day 2 Overview

Day 2 focused on window functions in PostgreSQL. These functions make it possible to perform calculations across related rows without grouping the results into fewer rows.

The exercises involved ranking customers and products, comparing current values with previous values, calculating month-over-month growth and generating cumulative revenue reports.

### Section B: Window Functions (Q6–Q10)

Question

Business Scenario

SQL Concept

### Q6

Rank the top three customers by lifetime revenue within each county.

DENSE_RANK() and PARTITION BY

### Q7

Identify the top three best-selling products in each category based on 2025 revenue.

ROW_NUMBER() and top-N per group

### Q8

Calculate monthly revenue growth compared with the previous month from January 2025 to October 2026.

LAG() and NULLIF()

### Q9

Compare each Nyeri customer's completed 2026 order with their previous order and classify spending direction.

LAG(), PARTITION BY and CASE

### Q10

Calculate monthly year-to-date revenue and an all-time cumulative revenue total.

SUM() OVER() and window frames

### Key Window Functions Practised

1. DENSE_RANK()

Used to rank customers within their respective counties based on lifetime revenue. Customers with equal revenue receive the same rank.

2. ROW_NUMBER()

Used to assign a unique sequential number to products within each category, helping identify the top three products by revenue.

3. LAG()

Used to retrieve values from previous rows. It was applied to:

Compare monthly revenue with the previous month.

Compare customers' current orders with their previous orders.

4. SUM() OVER()

Used to calculate cumulative revenue without collapsing monthly records into a single row.

5. PARTITION BY

Used to divide records into groups, such as counties, product categories, customers or calendar years, before applying window calculations.

6. Window Frames

Practised the explicit window frame:

ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

This was used to calculate running totals from the first row up to the current row.

### Business Analysis Applications – Day 2

The window function exercises demonstrated how SQL can support business decision-making through:

Customer segmentation: Ranking high-value customers within different counties.

Inventory planning: Identifying the best-selling products in each category to guide future stock decisions.

Revenue monitoring: Tracking month-over-month revenue changes and identifying growth or decline.

Customer behaviour analysis: Monitoring whether individual customers are increasing or reducing their order spending.

Financial reporting: Calculating year-to-date and cumulative revenue for financial performance monitoring.

### Key Learning Outcomes – Day 2

By completing the Day 2 exercises, I strengthened my ability to:

Apply window functions to business analysis problems.

Rank records within specific groups using PARTITION BY.

Differentiate between ROW_NUMBER() and DENSE_RANK().

Retrieve previous row values using LAG().

Calculate month-over-month revenue growth.

Use CASE statements to classify business performance.

Calculate running totals using SUM() OVER().

Apply window frames to control cumulative calculations.

### Overall Learning Outcomes

Through Day 1 and Day 2, I gained practical experience in:

Advanced SQL querying and data retrieval.

Subqueries, correlated subqueries and anti-joins.

Common Table Expressions and derived tables.

SQL functions and stored procedures.

Aggregate and window functions.

Customer, product and sales performance analysis.

Financial calculations and revenue reporting.

Translating business requirements into SQL queries.

### Conclusion

The first two days of the LuxDevHQ Cohort 9 Advanced SQL assignment provided practical experience in using PostgreSQL to solve real-world business problems.

Day 1 strengthened my understanding of subqueries, CTEs, derived tables, functions and stored procedures. Day 2 extended these skills through window functions, enabling more advanced analysis of customer rankings, product performance, revenue growth and cumulative financial results.

The exercises demonstrated how SQL can transform retail business data into meaningful insights that support inventory management, customer relationship management, sales monitoring and financial decision-making.
