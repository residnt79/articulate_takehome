
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from "dev"."main"."stg_subscriptions"

where not(end_date >= start_date)


  
  
      
    ) dbt_internal_test