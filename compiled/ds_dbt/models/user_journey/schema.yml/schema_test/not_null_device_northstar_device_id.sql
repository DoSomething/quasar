
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."device_northstar"
where device_id is null


