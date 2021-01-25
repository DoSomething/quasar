

  create  table "quasar"."public"."stg_zendesk_group__dbt_tmp"
  as (
    with base as (

    select *
    from "quasar"."ft_zendesk"."group"
    
), fields as (

    select

      id as group_id,
      name

    from base
    where not _fivetran_deleted


)

select *
from fields
  );