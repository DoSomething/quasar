{{
    config(
        materialized = 'incremental',
        unique_key = 'session_id'
    )
}}

with sessions as (

    select * from {{ref('snowplow_sessions')}}
    -- this is an output from the snowplow package

    {% if is_incremental() %}
        where session_start >= dateadd(day, -2, (select max(session_start) from {{this}}))
    {% endif %}

),

custom_structured_events as (
    
    select * from {{ ref('int_snowplow_custom_structured_events') }}
    
    {% if is_incremental() %}
        where collector_tstamp >= dateadd(day, -2, (select max(session_start) from {{this}}))
    {% endif %}
    
),

se_summary as (
    
    select 
        domain_sessionid as session_id, 
        
        max(case when is_member_conversion then 1 else 0 end) is_member_conversion_session,
        max(case when is_campaign_signup then 1 else 0 end) is_campaign_signup_session,
        max(case when is_campaign_post_visit then 1 else 0 end) is_campaign_post_session,
        sum(case when is_campaign_signup then 1 else 0 end) total_campaign_signups_in_session,
        sum(case when is_campaign_post_visit then 1 else 0 end) total_campaign_posts_in_session
    
    from custom_structured_events
    
    group by 1
    
),

enriched as (
    
    select 
        sessions.*,
        
        se_summary.is_member_conversion_session,
        se_summary.is_campaign_signup_session,
        se_summary.is_campaign_post_session,
        se_summary.total_campaign_signups_in_session,
        se_summary.total_campaign_signups_in_session
    
    from sessions 
    left join se_summary 
        on sessions.session_id = se_summary.session_id
    
)

select * from enriched