
  
  create view "dev"."main"."stg_customers__dbt_tmp" as (
    select
    id as customer_id
    , signup_date::date as signup_date
    , trim(status) as subscription_status
    , trim(region) as region
from "dev"."main"."customers"
  );
