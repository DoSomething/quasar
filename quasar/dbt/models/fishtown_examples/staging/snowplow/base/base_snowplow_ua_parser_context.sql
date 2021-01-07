-- TODO check on primary key of this table

{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}



with 

source as  (

    select * from {{ source('snowplow', 'ua_parser_context') }}
 
),

renamed as (
    
    select 
        source.*,
        
       -- Created partial B-tree index ua_parser_ctx_uagent_fam
       -- NOTE recreate index if the regex here changes
        useragent_family SIMILAR TO '%(bot|crawl|slurp|spider|archiv|spinn|sniff|seo|audit|survey|pingdom|worm|capture|(browser|screen)shots|analyz|index|thumb|check|facebook|YandexBot|Twitterbot|a_archiver|facebookexternalhit|Bingbot|Googlebot|Baiduspider|360(Spider|User-agent)|Ghost)%' as is_excluded_event
        -- not sure what to call this field! - DC
        -- looks like some events in my check queries have useragent_family = Facebook - should this be case sensitive?
        -- I also think this SIMILAR TO command is not performant - this could be moved into a mapping table in a seed?
        
    from source 

)

select * from renamed

where 1=1

{% if target.name == 'dev' %}

    and _fivetran_synced >= current_date -  {{ var('testing_days_of_data') }}
    
    limit 100

{% elif is_incremental() %}

    and _fivetran_synced >= (select max(_fivetran_synced) from {{ this }} )

{% endif %}
