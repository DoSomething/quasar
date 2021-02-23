
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."snowplow_sessions"
where ending_datetime is null


