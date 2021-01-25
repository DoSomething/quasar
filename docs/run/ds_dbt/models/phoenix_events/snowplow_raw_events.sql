
      

    insert into "quasar"."public"."snowplow_raw_events" ("action_id", "browser_size", "clicked_link_url", "device_id", "event_datetime", "event_id", "event_name", "event_source", "event_type", "host", "northstar_id", "referrer_host", "referrer_path", "referrer_source", "se_action", "se_category", "se_label", "session_counter", "session_id", "block_id", "campaign_id", "campaign_name", "context_source", "context_value", "group_id", "modal_type", "path", "page_id", "search_query", "utm_campaign", "utm_medium", "utm_source", "query_parameters")
    (
       select "action_id", "browser_size", "clicked_link_url", "device_id", "event_datetime", "event_id", "event_name", "event_source", "event_type", "host", "northstar_id", "referrer_host", "referrer_path", "referrer_source", "se_action", "se_category", "se_label", "session_counter", "session_id", "block_id", "campaign_id", "campaign_name", "context_source", "context_value", "group_id", "modal_type", "path", "page_id", "search_query", "utm_campaign", "utm_medium", "utm_source", "query_parameters"
       from "snowplow_raw_events__dbt_tmp20210121164635105407"
    );
  