
  create view "quasar"."public"."stg_typeform_nps_web__dbt_tmp" as (
    SELECT
token::varchar(256) as survey_id
, nps_score::int
, nps_reason::text
, northstar_id::varchar(256)
, url as surveyed_on_url
, submitted_at::timestamp as created_at

  FROM "quasar"."ft_google_sheets"."typeform_web_nps_survey"
  );
