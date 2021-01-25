

  create  table "quasar"."public"."stg_zendesk_organization__dbt_tmp"
  as (
    with base as (

    select *
    from "quasar"."ft_zendesk"."organization"

), fields as (

    select

      id as organization_id,
      details,
      name

    from base

)

select *
from fields
  );