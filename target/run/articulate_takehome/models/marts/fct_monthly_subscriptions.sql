
  
  create view "dev"."main"."fct_monthly_subscriptions__dbt_tmp" as (
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
    select * from "dev"."main"."stg_subscriptions"
)
, plans as (
    select * from "dev"."main"."stg_plans"
)
, customers as (
    select * from "dev"."main"."stg_customers"
)
, customer_months as (
    select m.month_start_date
        , m.month_end_date
        , customer_id
        , region
    from months m
    inner join customers c
    on m.month_start_date >= date_trunc('month', c.signup_date)
)
, subscriptions_expanded as (
    select cm.month_start_date
        , s.subscription_id
        , cm.customer_id
        , s.plan_id
        , row_number() over 
            (
                partition by cm.customer_id, cm.month_start_date 
                order by s.start_date desc, s.subscription_id desc
            ) as row_num
    from customer_months cm
    inner join subscriptions s
        on cm.customer_id = s.customer_id
        and s.start_date <= cm.month_end_date
        and s.end_date   >= cm.month_start_date
    qualify row_num = 1
)

select cm.month_start_date
    , cm.customer_id
    , case when se.subscription_id is not null then 'Active' else 'Cancelled' end as subscription_status
    , cm.region
    , case when se.subscription_id is not null then p.plan_name end as plan_name
    , case when se.subscription_id is not null then p.monthly_price else 0 end as monthly_price
from customer_months cm
left join subscriptions_expanded se
    on se.customer_id = cm.customer_id
    and se.month_start_date = cm.month_start_date
left join plans p
    on se.plan_id = p.plan_id
  );
