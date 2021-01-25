
      

    insert into "quasar"."public"."snowplow_payload_event" ("action_id", "block_id", "campaign_id", "context_source", "context_value", "event_id", "event_name", "ft_timestamp", "group_id", "modal_type", "page_id", "search_query", "utm_source", "utm_medium", "utm_campaign", "url")
    (
       select "action_id", "block_id", "campaign_id", "context_source", "context_value", "event_id", "event_name", "ft_timestamp", "group_id", "modal_type", "page_id", "search_query", "utm_source", "utm_medium", "utm_campaign", "url"
       from "snowplow_payload_event__dbt_tmp20210121163315902505"
    );
  