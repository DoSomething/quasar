

  create  table "quasar"."public"."stg_zendesk_ticket_tag__dbt_tmp"
  as (
    with base as (

    select *
    from "quasar"."ft_zendesk"."ticket_tag"

), fields as (
    
    select

      ticket_id,
      
      tag as tags
      
      
    from base

)

select *
from fields
  );