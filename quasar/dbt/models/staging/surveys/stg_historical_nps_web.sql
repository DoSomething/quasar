with historical_web_nps as (

   select * from {{ source ('historical_survey', '2018_2020_typeform_web_nps') }}
    )

select * from historical_web_nps
