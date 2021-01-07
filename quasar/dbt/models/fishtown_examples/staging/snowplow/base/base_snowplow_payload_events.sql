with 

source as (
    
    select * from {{ source('snowplow', 'snowplow_event') }}
    
), 

unnested as (

    select
        payload::jsonb #>> '{actionId}' AS action_id,
        payload::jsonb #>> '{blockId}' AS block_id,
        payload::jsonb #>> '{campaignId}' AS campaign_id,
        payload::jsonb #>> '{contextSource}' AS context_source,
        payload::jsonb #>> '{value}' AS context_value,
        event_id,
        payload::jsonb #>> '{name}' AS event_name,
        _fivetran_synced AS ft_timestamp,
        payload::jsonb #>> '{groupId}' AS group_id,
        payload::jsonb #>> '{modalType}' AS modal_type,
        payload::jsonb #>> '{pageId}' AS page_id,
        payload::jsonb #>> '{searchQuery}' AS search_query,
        payload::jsonb #>> '{utmSource}' AS utm_source,
        payload::jsonb #>> '{utmMedium}' AS utm_medium,
        payload::jsonb #>> '{utmCampaign}' AS utm_campaign,
        payload::jsonb #>> '{url}' AS link_clicked_url

    from source
)

select * from unnested

where 1=1

{% if target.name == 'dev' %}

    and ft_timestamp >= current_date -  {{ var('testing_days_of_data') }}

{% elif is_incremental() %}

    and ft_timestamp >= (select max(ft_timestamp) from {{ this }} )

{% endif %}
