with months_series as (
    select unnest(
         generate_series(
             '2024-01-01'::date,
             '2024-12-31'::date,
             interval '1 month'
     )) ::date as month_date
 )

select month_date as month_start_date
    , last_day(month_date) as month_end_date
from months_series