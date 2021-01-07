{{
    config(
        materialized='view'
    )
}}

with 

raw_events as (
    select * from {{ ref('base_snowplow_events') }}
),

parser as (
    select * from {{ ref('base_snowplow_ua_parser_context') }}
),

payload as (
    select * from {{ ref('base_snowplow_payload_events') }}
),

joined as (
    
    select 
    
        raw_events.*,
        payload.action_id,
        payload.block_id,
    	payload.campaign_id,
        payload.context_source,
    	payload.context_value,
    	payload.group_id,
    	payload.modal_type,
        payload.page_id,
    	payload.search_query,
        payload.clicked_link_url,
    	payload.utm_campaign,
    	payload.utm_medium,
    	payload.utm_source
        
    from raw_events
    left join parser 
        on raw_events.event_id = parser.event_id 
    left join payload 
        on raw_events.event_id = payload.event_id
    
    where 
        coalesce (parser.is_excluded_event, FALSE) = FALSE
        -- include only records where exclusion criteria = false, or no match in parser context
        -- DC
        
)

select * from joined