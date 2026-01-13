
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select active_customers
from "dev"."main"."fct_monthly_metrics"
where active_customers is null



  
  
      
    ) dbt_internal_test