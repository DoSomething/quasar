

  create  table "quasar"."public"."fct_nps_web_responses__dbt_tmp"
  as (
    select *
from "quasar"."public"."stg_nps_web_responses"
  );