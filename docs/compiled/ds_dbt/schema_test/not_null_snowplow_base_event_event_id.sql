



select count(*)
from "quasar_prod_warehouse"."public"."snowplow_base_event"
where event_id is null
