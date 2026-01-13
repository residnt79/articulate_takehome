select
    id as customer_id
    , signup_date::date as signup_date
    , trim(status) as customer_status
    , trim(region) as region
from "dev"."main"."customers"