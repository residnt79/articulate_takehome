
  
  create view "dev"."main"."stg_subscriptions__dbt_tmp" as (
    select
    id as subscription_id
    , customer_id
    , plan_id
    , start_date::date as start_date
    , coalesce(end_date, '9999-12-31')::date as end_date
from "dev"."main"."subscriptions"
  );
