# Data Analyst Assessment: SQL Proficiency

## Overview
This assessment evaluates SQL skills in solving business problems through data retrieval, aggregation, joins, subqueries, and data manipulation across multiple tables.

### Database Schema
The database contains these tables:
- `adashi_staging.users_customuser`: Customer demographics
- `adashi_staging.savings_savingsaccount`: Deposit transactions
- `adashi_staging.plans_plan`: Customer plans
- `adashi_staging.withdrawals_withdrawal`: Withdrawal transactions

---

## Evaluation Criteria
| Criteria        | Description                          |
|-----------------|--------------------------------------|
| Accuracy        | Correct query results                |
| Efficiency      | Optimal query structure              |
| Completeness    | Full requirement coverage            |
| Readability     | Clean formatting and documentation   |

---

## Submission Requirements
1.  Create public repo: `DataAnalytics-Assessment`
2.  File structure:

    DataAnalytics-Assessment/
    ├── Assessment_Q1.sql
    ├── Assessment_Q2.sql
    ├── Assessment_Q3.sql
    ├── Assessment_Q4.sql
    └── README.md

3.  SQL files must:
    -   Contain one query per file
    -   Use proper indentation
    -   Include complex logic comments

---

## Assessment Questions
1.  **High-Value Customers**: Identify customers with both funded savings and investment plans, sorted by total deposits.
2.  **Transaction Frequency**: Calculate average transactions per customer per month with categorization.
3.  **Inactivity Alert**: Find active accounts with no deposits in 1 year.
4.  **CLV Estimation**: Calculate customer lifetime value based on tenure/transactions.

---

## Solution Documentation

### Per-Question Approach and Challenges

#### Question 1: High-Value Customers

* **Approach:** Used a two-step aggregation with **Common Table Expressions (CTEs)** to first count savings/investment plans for dual-plan owners, then pre-aggregate successful deposits. These CTEs were then joined with user data for the final output, ordered by total deposits.

* **Key Operations:** Common Table Expressions (CTEs), Conditional Aggregation, Group Filtering (HAVING), Data Aggregation, Table Joins, Data Formatting

* **Challenges:**
    * **Filtering for Dual-Plan Owners:** Identifying users with both plan types was complex; solved using `COUNT(CASE WHEN ...)` with a `HAVING` clause for efficient identification.
    * **Varied Transaction Statuses:** `transaction_status` column presented diverse values; `LIKE '%success%'` was adopted for consistent and comprehensive filtering of successful transactions.
    * **Raw Deposit Readability:** Raw deposit amounts lacked formatting; improved by using `FORMAT()` for separators, and converting **kobo to Naira** (dividing by 100).
    * **Sorting Formatted Currency:** Sorting formatted `total_deposits` (now a string) accurately was achieved by ordering by the **underlying numeric value** (`td.total_confirmed_amount`).

#### Question 2: Transaction Frequency

* **Approach:** Employed a CTE to calculate the monthly transaction rate per user, accounting for tenure. The main query then used a `CASE` statement to categorize users into frequency bins (`High`, `Medium`, `Low`) and aggregated counts and averages per category.

* **Key Operations:** Common Table Expressions (CTEs), Date Difference Calculation, Division-by-Zero Handling, Conditional Categorization (CASE), Data Aggregation

* **Challenges:**
    * **Calculating Months Since Creation:** Ensuring accurate "months since creation" for monthly rates was key; `TIMESTAMPDIFF()` provided a robust, scalable solution.
    * **Division-by-Zero Errors:** Preventing division by zero for new users (zero months tenure) was critical; solved by implementing `NULLIF()` for the denominator, allowing graceful handling of `NULL` results.
    * **Defining "Transactions":** Clarified "transactions" as **inflow events** from `savings_savingsaccount`, based on specified tables and typical context.

#### Question 3: Inactivity Alert

* **Approach:** Utilized a CTE with a nested subquery to identify inactive owners (no successful transactions in the past year) and retrieve details of their latest plan activity. The final join with `plans_plan` helped categorize plan types and filter for relevant results.

* **Key Operations:** Common Table Expressions (CTEs), Nested Subqueries, Date Difference Calculation, Data Aggregation, Table Joins

* **Challenges:**
    * **Identifying the "Latest Transaction":** Capturing the overall latest successful transaction was complex; the join logic inadvertently limited output to plans from that *single* date, a key learning about join impacts.
    * **Efficient Pre-filtering:** Achieved by using a subquery with `MAX()`, `GROUP BY`, and `HAVING` to effectively pre-filter inactive owners.
    * **Categorizing Diverse Plan Types:** Handled using a `CASE` statement, with a `WHERE` clause to filter for specific types like `Savings` or `Investments`.

#### Question 4: CLV Estimation
* **Approach:** Structured the query using a CTE to perform all **numeric CLV calculations**, including handling `tenure_months` and `total_transactions`, with a robust formula using `NULLIF()` for division-by-zero prevention. The main query then formatted the CLV for display while ensuring correct numerical sorting by leveraging the numeric value from the CTE.

* **Key Operations:** Common Table Expressions (CTEs), Complex Mathematical Calculations, Division-by-Zero Handling, Data Aggregation, String Formatting, Numeric Ordering

* **Challenges:**
    * **Complex CLV Calculation:** The CLV formula was inherently complex and prone to **division-by-zero errors**; made robust by simplifying the expression and implementing `NULLIF()`.
    * **Sorting Formatted CLV:** Displaying CLV as a **formatted currency string** while ensuring **correct numerical sorting** was a challenge; resolved by using a CTE to calculate the numeric value, then sorting by it while displaying the formatted string.

---

### Caveats and Key Insights

Throughout this project, several important data peculiarities, interpretation assumptions, and user behavior insights emerged:

* **Data Nuances:**
    * The `transaction_status` column frequently contained varied "success" strings; `LIKE '%success%'` was consistently used for filtering, though `='success'` could offer better performance for exact matches.
    * The `created_on` column from `users_customuser` was preferred over `date_joined` as it sometimes provided a slightly earlier (more precise) signup timestamp.
    * Encountered **duplicate names** associated with unique user IDs, underscoring the critical importance of always using **`user_id` as the primary identifier** for all aggregations and joins.

* **User Behavior & Activation:**
    * An interesting finding was the presence of users who created plans (`plans_plan`) but had no corresponding deposits (`savings_savingsaccount`). This suggests a potential **onboarding or activation gap**, as these users created plans but never funded them.

* **Metric Interpretation (CLV):**
    * The CLV calculation strictly assumed **successful inflow transactions** based on available data and query scope.
    * CLV estimates for users with **very recent sign-up dates can be inflated** due to a low denominator (tenure months), requiring cautious interpretation for this segment.
    * A few instances of **exceptionally high CLV values** were observed from users with large early deposits and short tenure, potentially indicating outliers that warrant deeper analysis.

---

## ERD Documentation
![ERD Diagram](https://github.com/WaleOye-517/DataAnalytics-Assessment/blob/2d7f8b991ca2932a478bc8c41b1240dc49e2ac65/erd.jpg)

### Entity Relationships
-   `users_customuser` → `plans_plan` (1:m)
-   `plans_plan` → `savings_savingsaccount` (1:m)
-   `plans_plan` → `withdrawals_withdrawal` (1:m)