
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."snowplow_payload_event"
where event_id is null


