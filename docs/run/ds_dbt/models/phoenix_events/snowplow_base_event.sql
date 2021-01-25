
      

    insert into "quasar"."public"."snowplow_base_event" ("event_id", "event_source", "event_datetime", "event_name", "event_type", "host", "path", "query_parameters", "se_category", "se_action", "se_label", "session_id", "session_counter", "browser_size", "northstar_id", "device_id", "referrer_host", "referrer_path", "referrer_source")
    (
       select "event_id", "event_source", "event_datetime", "event_name", "event_type", "host", "path", "query_parameters", "se_category", "se_action", "se_label", "session_id", "session_counter", "browser_size", "northstar_id", "device_id", "referrer_host", "referrer_path", "referrer_source"
       from "snowplow_base_event__dbt_tmp20210121163312124887"
    );
  