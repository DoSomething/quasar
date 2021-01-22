SELECT
token::varchar(256) as survey_response_id
, nps_score::int
, nps_reason::text
, northstar_id::varchar(256)
, url as surveyed_on_url
, submitted_at::timestamp as created_at

  FROM {{ source('gsheets', 'typeform_web_nps_survey') }}
