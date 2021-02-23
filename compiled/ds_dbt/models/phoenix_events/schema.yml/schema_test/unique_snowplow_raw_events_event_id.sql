
    
    



select count(*) as validation_errors
from (

    select
        event_id

    from "quasar_prod_warehouse"."public"."snowplow_raw_events"
    where event_id is not null
    group by event_id
    having count(*) > 1

) validation_errors


