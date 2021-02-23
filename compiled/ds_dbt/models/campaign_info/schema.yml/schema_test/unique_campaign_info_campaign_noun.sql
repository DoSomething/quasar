
    
    



select count(*) as validation_errors
from (

    select
        campaign_noun

    from "quasar_prod_warehouse"."public"."campaign_info"
    where campaign_noun is not null
    group by campaign_noun
    having count(*) > 1

) validation_errors


