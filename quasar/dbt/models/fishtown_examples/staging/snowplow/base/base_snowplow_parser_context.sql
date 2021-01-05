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
    from source 

)

select * from renamed