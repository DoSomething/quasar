
SELECT
id as survey_id
, nps_score
, nps_reason
, northstar_id
, url as surveyed_on_url
, legacy_campaign_id
, submit_date as created_at

  FROM {{ source('survey', '2018_2020_typeform_web_nps') }}
