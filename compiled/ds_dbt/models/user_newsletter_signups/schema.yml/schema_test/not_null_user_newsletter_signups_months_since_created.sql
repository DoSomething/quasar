
    
    



select count(*) as validation_errors
from "quasar_prod_warehouse"."public"."user_newsletter_signups"
where months_since_created is null


