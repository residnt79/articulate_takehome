



select
    1
from "dev"."main"."stg_subscriptions"

where not(end_date >= start_date)

