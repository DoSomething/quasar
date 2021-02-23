
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."campaign_info_international"
where campaign_run_id_title is null


