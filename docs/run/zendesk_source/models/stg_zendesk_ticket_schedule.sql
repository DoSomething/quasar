

  create  table "quasar"."public"."stg_zendesk_ticket_schedule__dbt_tmp"
  as (
    

with base as (

    select *
    from "quasar"."ft_zendesk"."ticket_schedule"

), fields as (
    
    select

      ticket_id,
      created_at,
      cast(schedule_id as 
    varchar
) as schedule_id --need to convert from numeric to string for downstream models to work properly

    from base

)

select *
from fields
  );