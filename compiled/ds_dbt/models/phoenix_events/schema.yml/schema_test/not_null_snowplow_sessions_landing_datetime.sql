
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."snowplow_sessions"
where landing_datetime is null


