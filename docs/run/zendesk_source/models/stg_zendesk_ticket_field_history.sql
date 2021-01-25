

  create  table "quasar"."public"."stg_zendesk_ticket_field_history__dbt_tmp"
  as (
    with base as (

    select *
    from "quasar"."ft_zendesk"."ticket_field_history"

), fields as (
    
    select
    
      ticket_id,
      field_name,
      updated as valid_starting_at,
      lead(updated) over (partition by ticket_id, field_name order by updated) as valid_ending_at,
      value,
      user_id

    from base
    order by 1,2,3

)

select *
from fields
  );