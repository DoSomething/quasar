
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."ovrd_group_creator_funnel"
where device_id is null


