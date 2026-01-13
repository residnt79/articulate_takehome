
  
  create view "dev"."main"."stg_plans__dbt_tmp" as (
    select
    id as plan_id
    , trim(plan_name) as plan_name
    , monthly_price::decimal(6, 2) as monthly_price
from "dev"."main"."plans"
  );
