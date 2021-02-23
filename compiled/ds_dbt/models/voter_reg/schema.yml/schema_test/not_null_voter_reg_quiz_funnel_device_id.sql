
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."voter_reg_quiz_funnel"
where device_id is null


