
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."campaign_info"
where campaign_node_id_title is null


