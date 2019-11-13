



select count(*)
from (

    select
        event_source

    from "quasar_prod_warehouse"."public"."snowplow_base_event"
    where event_source is not null
    group by event_source
    having count(*) > 1

) validation_errors

