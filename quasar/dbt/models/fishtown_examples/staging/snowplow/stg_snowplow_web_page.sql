with 

source as (
    
    select * from {{ source('snowplow', 'web_page') }}

)

select * from source 

where 1=1

{% if target.name == 'dev' %}

    and _fivetran_synced >= current_date -  {{ var('testing_days_of_data') }}

{% elif is_incremental() %}

    and _fivetran_synced >= (select max(_fivetran_synced) from {{ this }} )

{% endif %}
