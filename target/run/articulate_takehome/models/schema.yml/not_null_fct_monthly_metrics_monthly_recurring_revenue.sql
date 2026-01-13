
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select monthly_recurring_revenue
from "dev"."main"."fct_monthly_metrics"
where monthly_recurring_revenue is null



  
  
      
    ) dbt_internal_test