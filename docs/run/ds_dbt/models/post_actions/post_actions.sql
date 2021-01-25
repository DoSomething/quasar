

  create  table "quasar"."public"."post_actions__dbt_tmp"
  as (
    SELECT *
FROM "quasar"."ft_rogue_dosomething_rogue_qa"."actions"
  );