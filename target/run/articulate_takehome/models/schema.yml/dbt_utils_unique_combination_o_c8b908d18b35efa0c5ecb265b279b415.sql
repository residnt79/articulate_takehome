
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  





with validation_errors as (

    select
        customer_id, month_start_date
    from "dev"."main"."fct_monthly_subscriptions"
    group by customer_id, month_start_date
    having count(*) > 1

)

select *
from validation_errors



  
  
      
    ) dbt_internal_test