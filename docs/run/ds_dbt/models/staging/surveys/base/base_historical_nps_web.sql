
  create view "quasar"."public"."base_historical_nps_web__dbt_tmp" as (
    SELECT
id::varchar(256) as survey_response_id
, nps_score::int
, (case when nps_score::int <= 6 then 'detractor'
     when nps_score::int <= 8 then 'passive'
     when nps_score::int <= 10 then 'promoter'
     else 'invalid score' end) as net_promoter_cat
, nps_reason::text
, northstar_id::varchar(256)
, url as surveyed_on_url
, legacy_campaign_id
, submit_date::timestamp as created_at

  FROM "quasar"."survey"."2018_2020_typeform_web_nps"
  );
