# LuxDevHQ Cohort 9 – Advanced SQL Assignment
## Day 1: SQL Practice and Querying – SokoMart Kenya

### 1. Project Overview

This project documents my Day 1 practical exercises for the LuxDevHQ Cohort 9 Advanced SQL assignment. The exercises use PostgreSQL to analyse data from a fictional Kenyan retail business, **SokoMart Kenya**.

The main objective was to strengthen my understanding of advanced SQL concepts and apply them to real-world business scenarios involving customers, products, orders, payments, sales and revenue.

### 2. Tools and Technologies

- **Database:** PostgreSQL
- **SQL Client:** DBeaver
- **Database Schema:** `sokomart`
- **Language:** SQL and PL/pgSQL

### 3. Tasks Completed

#### Part 1: Day 1 Practice Drills (D1–D10)

| Task | Exercise | SQL Concept |
|---|---|---|
| D1 | Identify products priced above the overall average price. | Scalar subqueries |
| D2 | Find Mombasa customers who placed orders in December 2025. | `IN` subqueries |
| D3 | Find Kisumu customers with failed payments. | Correlated `EXISTS` |
| D4 | Analyse order lines and units by order status. | Derived tables |
| D5 | Identify the top five shipping counties by completed orders in 2026. | Common Table Expressions (CTEs) |
| D6 | Compare monthly completed orders against the average. | Chained CTEs |
| D7 | Create a function to count orders for a customer. | SQL functions |
| D8 | Create a procedure to update customer status with validation. | Stored procedures and PL/pgSQL |
| D9 | Identify Beauty products with below-average stock. | CTEs and subqueries |
| D10 | Create a procedure to summarise customers and revenue by county. | Stored procedures with IN and OUT parameters |

#### Part 2: Section A – Business Analysis Questions (Q1–Q5)

| Question | Business Scenario | SQL Concept |
|---|---|---|
| Q1 | Identify customers whose 2025 spending was above average. | CTEs and scalar subqueries |
| Q2 | Identify active products priced above their category average. | Correlated subqueries |
| Q3 | Prepare a monthly profit and loss report for January–October 2026. | Multiple chained CTEs |
| Q4 | Identify Nakuru customers who purchased from at least three product categories. | Derived tables and `COUNT(DISTINCT)` |
| Q5 | Identify products that have never appeared on any order. | `NOT EXISTS` and anti-joins |

### 4. Key SQL Concepts Practised

During the exercises, I worked with:

- **Subqueries:** Using queries inside other queries to filter and analyse data.
- **Correlated subqueries:** Connecting an inner query to the current row of an outer query.
- **EXISTS and NOT EXISTS:** Checking whether matching records exist or do not exist.
- **CTEs:** Organising complex queries into manageable steps using `WITH`.
- **Derived tables:** Using subqueries in the `FROM` clause.
- **Aggregate functions:** Applying `COUNT()`, `SUM()`, `AVG()` and `ROUND()`.
- **Window-free analysis:** Solving category and monthly analysis questions without window functions.
- **Functions and stored procedures:** Creating reusable database routines using SQL and PL/pgSQL.
- **Date functions:** Using `DATE_TRUNC()` and `GENERATE_SERIES()` for monthly analysis.
- **Conditional calculations:** Using `CASE`, `COALESCE()` and `NULLIF()`.

### 5. Business Analysis Applications

The exercises demonstrated how SQL can support business decision-making by:

1. Identifying high-value customers based on purchasing behaviour.
2. Supporting product pricing decisions through category-level price comparisons.
3. Monitoring monthly revenue, costs, gross profit and profit margins.
4. Identifying cross-category customers for targeted marketing campaigns.
5. Identifying products that have never been ordered to support inventory and shelf-space decisions.
6. Analysing customer payments, order trends and regional performance.

### 6. Learning Outcomes

By completing the Day 1 exercises, I strengthened my ability to:

- Write and interpret nested SQL queries.
- Use correlated subqueries to perform row-level comparisons.
- Break complex problems into smaller steps using CTEs.
- Analyse customer purchasing patterns and product performance.
- Calculate business metrics such as revenue, cost, gross profit and profit margin.
- Create reusable SQL functions and stored procedures.
- Apply SQL concepts to practical retail business scenarios.

### 7. Conclusion

Day 1 provided practical experience in using PostgreSQL for data retrieval, business analysis and database programming. The exercises improved my understanding of subqueries, CTEs, derived tables, functions and stored procedures while demonstrating how SQL can transform raw retail data into meaningful business insights.

