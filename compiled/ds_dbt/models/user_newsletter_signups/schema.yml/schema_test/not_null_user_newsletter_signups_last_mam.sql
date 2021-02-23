
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."user_newsletter_signups"
where last_mam is null


