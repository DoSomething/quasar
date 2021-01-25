
      

    insert into "quasar"."public"."snowplow_sessions" ("session_id", "first_event_id", "device_id", "landing_datetime", "ending_datetime", "session_referrer_host", "session_utm_source", "session_utm_campaign", "session_duration_seconds", "num_pages_viewed", "landing_page", "exit_page", "days_since_last_session")
    (
       select "session_id", "first_event_id", "device_id", "landing_datetime", "ending_datetime", "session_referrer_host", "session_utm_source", "session_utm_campaign", "session_duration_seconds", "num_pages_viewed", "landing_page", "exit_page", "days_since_last_session"
       from "snowplow_sessions__dbt_tmp20210121164751763909"
    );
  