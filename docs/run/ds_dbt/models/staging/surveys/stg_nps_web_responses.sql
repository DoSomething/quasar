
  create view "quasar"."public"."stg_nps_web_responses__dbt_tmp" as (
    with nps_web_historic as
    (select
        survey_response_id
        , nps_score
        , net_promoter_cat
        , nps_reason
        , northstar_id
        , surveyed_on_url
        , legacy_campaign_id
        , created_at
       from "quasar"."public"."base_historical_nps_web" )

, nps_web_current as
    (select
      survey_response_id
      , nps_score
      , net_promoter_cat
      , nps_reason
      , northstar_id
      , surveyed_on_url
      , null as legacy_campaign_id
      , created_at
      from "quasar"."public"."base_typeform_nps_web" )

, final as
    (select * from nps_web_historic
      union all
      select * from nps_web_current)

select * from final
  );
