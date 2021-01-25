

  create  table "quasar"."public"."northstar_users_deduped__dbt_tmp"
  as (
    SELECT DISTINCT ON (northstar_id, updated_at) *
FROM "quasar"."public"."northstar_users_raw"
  );