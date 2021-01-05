{{
    config(
        materialized='incremental',
        unique_key='event_id'
    )
}}

with 

events as (
    select * from {{ ref('stg_snowplow_events') }}
),

payload_info as (
    select * from {{ ref('stg_snowplow_payload_events') }}
),

campaign_info as (
    select * from {{ ref('campaign_info') }}    
),

joiend as (
    
    -- Combines attributes from the ft_snowplow.event and ft_snowplow.snowplow_event schemas
    -- removes duplicate events by event_id
    -- DC - this shouldn't be a distinct - where are the dupes coming from
    SELECT DISTINCT ON (events.event_id, events.event_name, events.event_datetime)
    	payload_info.action_id,
    	events.browser_size,
    	payload_info.url AS clicked_link_url,
    	events.device_id,
    	events.event_datetime,
    	events.event_id,
    	CASE
    		WHEN events.event_name IS NULL
    		AND events.event_type = 'pv' THEN 'view'
    		ELSE events.event_name
    	END AS event_name,
    	events.event_source,
    	events.event_type,
    	events."host",
    	events.northstar_id,
    	events.referrer_host,
    	events.referrer_path,
    	events.referrer_source,
    	events.se_action,
    	events.se_category,
    	events.se_label,
    	events.session_counter,
    	events.session_id,
    	payload_info.block_id,
    	payload_info.campaign_id,
    	campaign_info.campaign_name,
    	payload_info.context_source,
    	payload_info.context_value,
    	payload_info.group_id,
    	payload_info.modal_type,
    	events."path",
    	payload_info.page_id,
    	payload_info.search_query,
    	payload_info.utm_campaign,
    	payload_info.utm_medium,
    	payload_info.utm_source,
        events.query_parameters
      FROM events
      LEFT JOIN payload_info ON events.event_id = payload_info.event_id
      LEFT JOIN campaign_info ON campaign_info.campaign_id = payload_info.campaign_id::bigint


    {% if is_incremental() %}
      -- this filter will only be applied on an incremental run
      WHERE events.event_datetime >= (select max(sre.event_datetime) from {{this}} sre)
    {% endif %}
    
    
)