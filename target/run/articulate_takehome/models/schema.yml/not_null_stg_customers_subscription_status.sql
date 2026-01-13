
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select subscription_status
from "dev"."main"."stg_customers"
where subscription_status is null



  
  
      
    ) dbt_internal_test