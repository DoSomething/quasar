SELECT
    nspt.event_id,
    nspt.useragent_family,
    nspt.useragent_major,
    nspt.useragent_minor,
    nspt.useragent_patch,
    nspt.useragent_version,
    nspt.os_family,
    nspt.os_major,
    nspt.os_minor,
    nspt.os_patch,
    nspt.os_patch_minor,
    nspt.os_version,
    nspt.device_family,
    nspt._fivetran_synced
FROM
    {{ source('snowplow_20200813', 'ua_parser_context') }} nspt
UNION
SELECT
    ospt.event_id,
    ospt.useragent_family,
    ospt.useragent_major,
    ospt.useragent_minor,
    ospt.useragent_patch,
    ospt.useragent_version,
    ospt.os_family,
    ospt.os_major,
    ospt.os_minor,
    ospt.os_patch,
    ospt.os_patch_minor,
    ospt.os_version,
    ospt.device_family,
    ospt._fivetran_synced
FROM
    {{ source('snowplow', 'ua_parser_context') }} ospt
