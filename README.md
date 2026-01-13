
# Articulate Take Home - Jason Scott

## Overview:

This dbt project transforms the raw customer, subscriptions and plan data into three monthly metrics:
- **Active Customers** - Number of distinct customers with at least one active subscription overlapping the month.
- **Monthly Recurring Revenue (MRR)** - Sum on monthly plan prices for active subscriptions in the month.
- **Logo Churn Rate** - Percentage of customers who were active in the prior month and have no active subscription in the current month.

## Quick Start:
**The database is prebuilt within DuckDB and ready to query**
Open 'dev.duckdb' with any DuckDB client and query:

```sql
select * 
from fct_monthly_metrics 
order by month_start_date
```

**profiles.yml**
```yml
articulate_takehome:
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      threads: 1
  target: dev
```

## Project Structure:
```
models
    - staging
        - stg_customers.sql
        - stg_subscriptions.sql
        - stg_plans.sql
    - marts
        - fct_monthly_subscriptions.sql
        - fct_monthly_metrics.sql
```

## Table Design
### fct_monthly_subscriptions
**Grain:** Customer-Month (One row per customer per month)

I chose this grain to preserve customer-level detail while aggregating to a monthly snapshot. The model generates all months in 2024 and joins to `stg_customers`, `stg_subscriptions` to derive monthly subscription status, with `stg_plans` attributes added for context and pricing.”

**Materialization:**
I used views for the take home. In production I'd use incremental with a monthly partition strategy to maintain idempotency, and each subsequent dbt run would only process new months.

**Subscription Status Logic:**

The raw customer table contains a `status` field that appears to be a point-in-time snapshot.

I recalculated subscription_status by:
  - Creating a customer-month spine based on the each customers signup_date.
  - Identifying susbscriptions that overlap each month. 
  - Using row_number to select the most recently started subscription when multiple subscriptions overlap the same month.
  - Deriving subscription status based on whether an active subscription exists for the month.
   
A customer is considered Active in a given month if at least one subscription overlaps the month window. If no subscriptions overlaps the month, the customer is considered 'Cancelled' for that month.
  
```sql
    case when se.subscription_id is not null then 'Active' else 'Cancelled' end as subscription_status
``` 
**Assumptions:**
- A subscription is "Active" for a month if it overlaps any partion of that month
- The subscriptions table is the source of truth for subscription activity, not `customer_status`
- Monthly dates generated using `generate_series()`. In production this would be replaced with a shared `dim_date` table.

**Tradeoffs:**
- **Storage vs Compute:** This approach creates one row per customer per month (including cancelled months), increasing row volume but eliminating the need to recalculate subscription status at query time.
- **Completeness:** Representing every customer in every month after signup makes lifecycle transitions explicit and simplifies churn analysis using window functions functions.

### fct_monthly_metrics
**Grain:** Month (One row per calendar month)

This model aggregates customer-month detail from `fct_monthly_subscriptions` to produce the three required metrics:

**Active Customers:**
```sql
count(distinct case when subscription_status = 'Active' then customer_id end)
```
Counts distinct customers with at least one active subscription overlapping the month.

**Monthly Recurring Revenue (MRR):**
```sql
sum(case when subscription_status = 'Active' then monthly_price else 0 end)
```
Represents the monthly subscription price from active subscriptions. MRR is not prorated.

**Logo Churn Rate:**
```sql
round(100.0 * coalesce(churned_users * 1.0 / nullif(active_previous_month, 0), 0), 2)
```
- Uses `LAG(subscription_status)` to identify customers whose subscription status transitions from Active in the prior month to Cancelled in the current month.
- Logo Churn Rate = (churned customers / customers active in the previous month) * 100

**Tradeoffs:**
- **Two tables vs one:** Separating customer-month detail (`fct_monthly_subscriptions`) from month-level aggregates (`fct_monthly_metrics`) increases maintenance overhead but provides flexibility for both detailed analysis and fast dashboard consumption.

## Data Tests
- Uniqueness and not-null tests on primary keys in staging models
- Grain tests: Unique combination on (`customer_id`, `month_start_date`) for `fct_monthly_subscriptions`
- Value validation: accepted values for `subscription_status`
- Logical constraints: end_date >= start_date, monthly_price > 0