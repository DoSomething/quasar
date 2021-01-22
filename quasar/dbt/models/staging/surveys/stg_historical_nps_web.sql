
SELECT
id::varchar(256) as survey_response_id
, nps_score::int
, nps_reason::text
, northstar_id::varchar(256)
, url as surveyed_on_url
, legacy_campaign_id
, submit_date::timestamp as created_at

  FROM {{ source('survey', '2018_2020_typeform_web_nps') }}
