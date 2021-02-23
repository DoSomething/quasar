

  with exceptions as (
    select
      count(*)

    from
      "quasar_prod_warehouse"."public"."snowplow_raw_events"

    where
      modal_type is null
      and event_name similar to '%(opened_modal|closed_modal)%'

  )

  select * from exceptions

