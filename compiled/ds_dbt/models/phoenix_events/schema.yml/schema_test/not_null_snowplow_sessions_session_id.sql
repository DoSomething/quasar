
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."snowplow_sessions"
where session_id is null


