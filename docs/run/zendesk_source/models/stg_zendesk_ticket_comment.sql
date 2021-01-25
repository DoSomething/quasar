

  create  table "quasar"."public"."stg_zendesk_ticket_comment__dbt_tmp"
  as (
    with base as (

    select *
    from "quasar"."ft_zendesk"."ticket_comment"

), fields as (

    select

      id as ticket_comment_id,
      _fivetran_synced,
      body,
      created as created_at,
      public as is_public,
      ticket_id,
      user_id,
      facebook_comment as is_facebook_comment,
      tweet as is_tweet,
      voice_comment as is_voice_comment

    from base

)

select *
from fields
  );