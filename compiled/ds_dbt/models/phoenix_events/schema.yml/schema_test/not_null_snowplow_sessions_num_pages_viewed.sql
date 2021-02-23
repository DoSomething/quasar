
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."snowplow_sessions"
where num_pages_viewed is null


