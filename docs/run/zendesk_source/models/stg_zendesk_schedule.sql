

  create  table "quasar"."public"."stg_zendesk_schedule__dbt_tmp"
  as (
    

with base as (

    select *
    from "quasar"."ft_zendesk"."schedule"

), fields as (
    
    select

      cast(id as 
    varchar
) as schedule_id, --need to convert from numeric to string for downstream models to work properly
      end_time_utc,
      start_time_utc,
      name as schedule_name,
      created_at
      
    from base
    where not _fivetran_deleted

)

select *
from fields
  );