



select count(*)
from "quasar_prod_warehouse"."public"."snowplow_sessions"
where exit_page is null
