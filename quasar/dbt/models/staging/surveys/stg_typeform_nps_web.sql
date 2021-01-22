SELECT
token as survey_id
, nps_score
, nps_reason
, northstar_id
, url as surveyed_on_url
, submit_date as created_at

  FROM {{ source('gsheets', 'typeform_web_nps_survey') }}
