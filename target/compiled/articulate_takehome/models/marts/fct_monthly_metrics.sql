with monthly_subscriptions as (
    select *
        , lag(subscription_status) over (partition by customer_id order by month_start_date) as previous_month_status
    from "dev"."main"."fct_monthly_subscriptions"
)
, aggregations as (
    select month_start_date
        , count(case when subscription_status = 'Active' then customer_id end) as active_customers
        , sum(case when subscription_status = 'Active' then monthly_price else 0 end) as monthly_recurring_revenue
        , count(case when subscription_status = 'Cancelled' and previous_month_status = 'Active' then customer_id end) as churned_users
        , count(case when previous_month_status = 'Active' then customer_id end) as active_previous_month
    from monthly_subscriptions
    group by month_start_date
)

select month_start_date
    , active_customers
    , monthly_recurring_revenue
    , round(100.0 * coalesce(churned_users / nullif(active_previous_month, 0), 0), 2) as logo_churn_rate
from aggregations
order by month_start_date