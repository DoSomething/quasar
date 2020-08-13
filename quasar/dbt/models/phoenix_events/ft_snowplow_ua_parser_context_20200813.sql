SELECT
    *
FROM
    {{ source('snowplow_20200813', 'ua_parser_context') }} nspt
UNION
SELECT
    *
FROM
    {{ source('snowplow', 'ua_parser_context') }} ospt
WHERE
    osp.collector_tstamp > '2020-07-28'
