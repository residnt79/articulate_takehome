
# Articulate Take Home - Jason Scott

## Overview:

This dbt project transforms the raw customer, subscriptions and plan data into three monthly metrics:
- **Active Customers** - Count of customers with active subscription
- **Monthly Recurring Revenue (MRR)** - Sum of subscription prices for active customers
- **Logo Churn Rate** - Percentage of customers who cancelled their subscription

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

I chose this grain to preserve customer-level detail while aggregating to a monthly snapshot. The model generates all months in 2024 and joins to `stg_subscriptions`, `stg_customer` and `stg_plans` to create a complete view of each customer's subscription state per month.

**Materialization:**
Views for the take home. In production I'd use incremental with a monthly partition strategy maintain idempotency, and each dbt run would only process new months.

**Subscription Status Logic:**

The raw customer table contains a `status` field that appears to be a point-in-time snapshot. I recalculated subscription_status per month using subscription start/end dates.
```sql
    case
        when s.start_date <= m.month_end_date
            and s.end_date >= m.month_start_date
        then 'Active' else 'Cancelled'
        end as subscription_status
``` 
**Assumptions:**
- A subscription is "Active" for a month if it covers any part of that month
- Subscriptions table is the source of truth for status, not `customer.subscription_status`
- Monthly dates using `generate_series()` in a CTE, production would use a proper `dim_date` table.

**Tradeoffs:**
- **Storage vs Compute:** This approach creates one row per customer per month (including cancelled months), increasing table storage but eliminates the need
  to recalculate subscription status on every query.
- **Completeness:** Every customer appears in every month after signup, making status transitions explicit and churn analysis straightforward using LAG() window
  functions.

### fct_monthly_metrics
**Grain:** Month (One row per month)

Built from `fct_monthly_subscriptions` by aggregating the three required metrics:

**Active Customers:**
```sql
count(case when subscription_status = 'Active' then customer_id end)
```
**Monthly Recurring Revenue (MRR):**
```sql
sum(case when subscription_status = 'Active' then monthly_price else 0 end)
```
**Logo Churn Rate:**
```sql
round(100.0 * coalesce(churned_users / nullif(active_previous_month, 0), 0), 2)
```
- Uses `LAG(subscription_status)` to identify customers who subscription status transitions from Active to Cancelled.
- Churn Rate = (churned customers / customers active previous month) * 100

**Tradeoffs:**
- **Two tables vs one:** Created both customer-month detail (`fct_monthly_subscriptions`) and month-level aggregates (`fct_monthly_metrics`) to serve different use cases. This adds maintenance overhead but provides flexibility for both detailed analysis and quick dashboard consumption.