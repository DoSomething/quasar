
    
    



select count(*) as validation_errors
from (

    select
        device_id

    from "quasar_prod_warehouse"."public"."snowplow_sessions"
    where device_id is not null
    group by device_id
    having count(*) > 1

) validation_errors


