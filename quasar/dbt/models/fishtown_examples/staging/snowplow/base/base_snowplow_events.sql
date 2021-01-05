{{
    config(
        materialized='incremental',
        unique_key='event_id'
    )
}}

with source as (
    
    {{ source('snowplow', 'event') }}
    
),


renamed as (

    select
        event_id as event_id,
        app_id as event_source,
        collector_tstamp as event_datetime,
        case
          when
            -- https://www.pivotaltracker.com/story/show/171388718
            se_property = 'phoenix_failed_call_to_action_popover_submission'
          then
            'phoenix_failed_call_to_action_popover'
          else
            se_property end as event_name,
        "event" as event_type,
        page_urlhost as host,
        page_urlpath as "path",
        page_urlquery as query_parameters,
        case
          when
            -- https://www.pivotaltracker.com/story/show/171388472
            se_property similar to 'phoenix_clicked_nav_link_log_(in|out)' and se_category = 'navigation'
          then
            'authentication'
          else
            se_category 
        end as se_category,
        case
          when
            -- https://www.pivotaltracker.com/story/show/171161608
            ((se_property = 'phoenix_clicked_voter_registration_action' and se_action = 'undefined_clicked')
            or
            -- https://www.pivotaltracker.com/story/show/171392080
            (se_property = 'phoenix_clicked_nav_button_search_form_toggle' and se_action = 'link_clicked'))
          then
            'button_clicked'
          when
            -- https://www.pivotaltracker.com/story/show/171388922
            se_property ilike 'phoenix_dismissed_%' and se_action = 'dismissable_element_dismissed'
          then
            'element_dismissed'
          else
            se_action 
        end as se_action,
        case
          when
            -- https://www.pivotaltracker.com/story/show/171388718
            se_property = 'phoenix_failed_call_to_action_popover_submission' and se_label = 'call_to_action_popover_submission'
          then
            'call_to_action_popover'
          else
            se_label 
        end as se_label,
        domain_sessionid as session_id,
        domain_sessionidx as session_counter,
        dvce_type as browser_size,
        user_id as northstar_id,
        domain_userid as device_id,
        refr_urlhost as referrer_host,
        refr_urlpath as referrer_path,
        refr_source as referrer_source
    from
      source

)

select * from renamed

{% if is_incremental() %}
  -- this filter will only be applied on an incremental run
  and collector_tstamp >= (
    select
      max(sp_event.event_datetime)
    from
      {{ this }} sp_event
  )
{% endif %}
