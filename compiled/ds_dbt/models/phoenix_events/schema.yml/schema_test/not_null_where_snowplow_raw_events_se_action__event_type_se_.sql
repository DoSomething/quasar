

  with exceptions as (
    select
      count(*)

    from
      "quasar_prod_warehouse"."public"."snowplow_raw_events"

    where
      se_action is null
      and event_type = 'se'

  )

  select * from exceptions

