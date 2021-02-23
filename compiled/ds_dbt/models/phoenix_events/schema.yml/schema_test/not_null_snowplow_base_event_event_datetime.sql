
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."snowplow_base_event"
where event_datetime is null


