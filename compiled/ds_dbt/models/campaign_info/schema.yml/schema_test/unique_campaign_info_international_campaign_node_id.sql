
    
    



select count(*) as validation_errors
from (

    select
        campaign_node_id

    from "quasar_prod_warehouse"."public"."campaign_info_international"
    where campaign_node_id is not null
    group by campaign_node_id
    having count(*) > 1

) validation_errors


