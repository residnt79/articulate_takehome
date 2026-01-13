with months_series as (
    select unnest(
         generate_series(
             '2024-01-01'::date,
             '2024-12-31'::date,
             interval '1 month'
     )) ::date as month_date
 )
, months as(
    select month_date as month_start_date
        , last_day(month_date) as month_end_date
    from months_series
)
, subscriptions as (
    select * from {{ ref('stg_subscriptions') }}
)
, plans as (
    select * from {{ ref('stg_plans') }}
)
, customers as (
    select * from {{ ref('stg_customers') }}
)

select
    m.month_start_date
    , s.customer_id
    , case
        when s.start_date <= m.month_end_date
            and s.end_date >= m.month_start_date
        then 'Active' else 'Cancelled'
        end as subscription_status
    , c.region
    , p.plan_name
    , p.monthly_price
from months m
inner join subscriptions s
    on m.month_start_date >= date_trunc('month', s.start_date)
inner join plans p
    on s.plan_id = p.plan_id
inner join customers c
    on s.customer_id = c.customer_id
order by s.customer_id, m.month_start_date