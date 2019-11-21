



select count(*)
from (

    select
        campaign_run_start_date

    from "quasar_prod_warehouse"."public"."campaign_info_all"
    where campaign_run_start_date is not null
    group by campaign_run_start_date
    having count(*) > 1

) validation_errors
