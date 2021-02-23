
    
    



select count(*) as validation_errors
from (

    select
        campaign_run_id

    from "quasar_prod_warehouse"."public"."campaign_info"
    where campaign_run_id is not null
    group by campaign_run_id
    having count(*) > 1

) validation_errors


