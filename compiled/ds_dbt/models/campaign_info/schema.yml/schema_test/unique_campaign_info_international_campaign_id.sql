
    
    



select count(*) as validation_errors
from (

    select
        campaign_id

    from "quasar_prod_warehouse"."public"."campaign_info_international"
    where campaign_id is not null
    group by campaign_id
    having count(*) > 1

) validation_errors


