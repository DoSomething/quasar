{{
    config(
        materialized='incremental',
        unique_key='event_id'
    )
}}

with source as (
    
    select * from {{ source('snowplow', 'event') }}
    
),


renamed as (

    select
        source.*,
        
        "event" as event_type,
        CASE
    		WHEN event_name IS NULL
    		AND event = 'pv' THEN 'view'
    		ELSE event_name
    	END AS event_name_special
        /* possible re-write?
        CASE event
    		WHEN 'pv' THEN 'pageview'
            WHEN 'se' THEN 'structured_event'
            WHEN 'ue' THEN 'link_clicked'
    		ELSE event
    	END AS full_event_name,
        */
        
        /*
        page_urlhost,
        page_urlpath,
        page_urlquery,
        */
        
        /*
        
        
        I am removing renaming of columns here, as the snowplow package expects raw column names in order to work!
        Leaving these fields to be added by the select *
        
        -- domain_sessionid as session_id,
        -- domain_sessionidx as session_counter,
        -- dvce_type as browser_size,
        -- user_id as northstar_id,
        -- domain_userid as device_id,
        -- refr_urlhost as referrer_host,
        -- refr_urlpath as referrer_path,
        -- refr_source as referrer_source
        
        */
    from
      source

)

select * from renamed

where 1=1 

{% if target.name == 'dev' %}

    and collector_tstamp >= current_date -  {{ var('testing_days_of_data') }}
    
    limit 1000

{% elif is_incremental() %}

    and collector_tstamp >= (select max(collector_tstamp) from {{ this }} )

{% endif %}

