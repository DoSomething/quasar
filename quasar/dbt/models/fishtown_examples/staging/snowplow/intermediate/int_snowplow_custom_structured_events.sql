{{
    config(
        materialized='incremental',
        unique_key='event_id'
    )
}}

with structured_events as (
    
    select * from {{ ref('stg_snowplow_events') }}
    
    where 
        event = 'se'
    
        {% if target.name == 'dev' %}

        and collector_tstamp >= current_date) - {{ var('testing_days_of_data') }}

        {% elif is_incremental() %}

        and collector_tstamp >= (select max(collector_tstamp) from {{ this }})

    {% endif %}
),

event_tags as (
    
    select 
        {{ dbt_utils.star(from=ref('stg_snowplow_events'), except=["se_category", "se_action", "se_label", "se_property"]) }},
        
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
        
        
        case
            when se_property = 'phoenix_failed_call_to_action_popover_submission'
                then 'phoenix_failed_call_to_action_popover'
            else se_property
        end as se_property,
        
        se_property = 'northstar_submitted_register' and page_urlpath = '/register' as is_member_conversion,
        se_property = 'phoenix_clicked_signup' as is_campaign_signup,
        se_property in (
            'phoenix_submitted_photo_submission_action',
            'phoenix_submitted_referral_submission_action',
            'phoenix_submitted_voter_reg_submission_action',
            'phoenix_submitted_share_social_submission_action',    
            'phoenix_submitted_text_submission_action'    
        ) as is_campaign_post_visit
        
    from structured_events
    
)

select * from event_tags
