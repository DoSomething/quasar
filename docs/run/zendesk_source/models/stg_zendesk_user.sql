

  create  table "quasar"."public"."stg_zendesk_user__dbt_tmp"
  as (
    with base as (

    select *
    from "quasar"."ft_zendesk"."user"

), fields as (

    select

      id as user_id,
      _fivetran_synced,
      created_at,
      email,
      name,
      organization_id,
      role,
      ticket_restriction,
      time_zone,
      active as is_active

    from base

)

select *
from fields
  );