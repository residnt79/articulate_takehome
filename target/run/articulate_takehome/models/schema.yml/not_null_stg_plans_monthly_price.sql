
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select monthly_price
from "dev"."main"."stg_plans"
where monthly_price is null



  
  
      
    ) dbt_internal_test