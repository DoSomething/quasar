{{
    config(
        materialized = 'incremental',
        unique_key = 'page_view_id'
    )
}}

with 

page_views as (
    
    select * from {{ ref('snowplow_page_views') }}
    -- this model will be an output from the snowplow package
    {% if is_incremental() %}
        where page_view_start >= dateadd(day, -2, (select max(page_view_start) from {{this}}))
    {% endif %}
),

enriched as (
    
    select 
        page_views.*,
        
        case
            when path like '/us/campaigns/%'
                then TRUE 
            else FALSE 
        end as is_campaign_page_visit
        
    from 
    
)

select * from enriched