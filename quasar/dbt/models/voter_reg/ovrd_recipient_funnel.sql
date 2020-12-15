WITH funnel_base AS (
  SELECT
    pec.session_id,
    pec.device_id,
    pec.northstar_id,
    pec.event_name,
    pec.event_datetime
  FROM
    {{ ref('snowplow_raw_events') }}
    pec
    JOIN {{ ref('snowplow_sessions') }}
    psc
    ON (
      pec.session_id = psc.session_id
    ) --filter the url of interest
  WHERE
    pec."path" ILIKE '%my-voter-registration-drive%'
    AND pec.query_parameters NOT ILIKE '%group_id=%'
    AND pec.event_datetime >= '2020-03-01'
),
northstars AS (
  --Authenticated Users
  SELECT
    device_id,
    session_id,
    northstar_id
  FROM
    funnel_base
  WHERE
    northstar_id IS NOT NULL
  GROUP BY
    1,
    2,
    3
),
devices AS (
  --Anonymous Users (removes cases of sessions that started anonymous AND got autheticated afterwards)
  SELECT
    b.device_id,
    b.session_id
  FROM
    funnel_base b
    LEFT JOIN northstars n
    ON (
      b.session_id = n.session_id
      AND b.device_id = n.device_id
    )
  WHERE
    n.session_id IS NULL
  GROUP BY
    1,
    2
),
session_base AS (
  --Authenticated Sessions
  --Joining WITH users table to eliminate internal (dosomething.org) northstar_ids
  SELECT
    f.device_id,
    f.session_id,
    f.northstar_id
  FROM
    funnel_base f
    JOIN northstars n
    ON (
      f.session_id = n.session_id
    )
    JOIN {{ ref('users') }}
    u
    ON (
      f.northstar_id = u.northstar_id
    )
  UNION ALL
    --Anonymous Sessions
  SELECT
    f.device_id,
    f.session_id,
    NULL
  FROM
    funnel_base f
    JOIN devices d
    ON (
      f.device_id = d.device_id
      AND f.session_id = d.session_id
    )
),
post_base AS (
  --posts AND rbs WITH who came FROM a group-based referral per their rtv tracking source
  SELECT
    p.northstar_id,
    p.id,
    r.post_id,
    rtv.started_registration_utc AS event_ts,
    p.status AS event_name,
    CASE
      WHEN r.post_id IS NOT NULL THEN 1
    END AS registered
  FROM
    {{ ref('posts') }}
    p
    JOIN {{ ref('rock_the_vote') }}
    rtv
    ON p.id = rtv.post_id
    LEFT JOIN {{ ref('reportbacks') }}
    r
    ON p.id = r.post_id
  WHERE
    p.vr_source_details LIKE '%onlinedrivereferral%'
    AND rtv.tracking_source LIKE '%referral=true%'
    AND rtv.tracking_source NOT LIKE '%group_id=%'
    AND p.created_at >= '2020-03-01'
    AND rtv.started_registration_utc >= '2020-03-01'
) --collapse the event log to a user level table WITH flags AND timestamps
SELECT
  sb.session_id,
  sb.device_id,
  COALESCE(COALESCE(sb.northstar_id, pb.northstar_id)) AS northstar_id,
  pb.post_id,
  --earliest ts ON record is WHEN their journey began
  MIN(COALESCE(fb.event_datetime, pb.event_ts)) AS journey_begin_ts,
  --you must have visited the page if you are IN the event log (allows us to 'backfill' some of the missing info
  1 AS page_visit,
  --earliest rtv record for the user is WHEN they began registering
  MIN(
    CASE
      WHEN pb.event_name IS NOT NULL THEN COALESCE(
        fb.event_datetime,
        pb.event_ts
      )
    END
  ) AS started_register_ts,
  --if they have a any event THEN they clicked get started
  MAX(
    CASE
      WHEN pb.event_name IS NOT NULL THEN 1
      ELSE 0
    END
  ) AS clicked_get_started,
  --if they have any of the following steps, they made it to step 2
  MAX(
    CASE
      WHEN pb.event_name IN (
        'step-2',
        'step-3',
        'step-4',
        'ineligible',
        'under-18',
        'register-OVR',
        'register-form'
      ) THEN 1
      ELSE 0
    END
  ) AS rtv_step_2,
  --if they have any of the following steps, they made it to step 3
  MAX(
    CASE
      WHEN pb.event_name IN (
        'step-3',
        'ineligible',
        'under-18',
        'register-form'
      ) THEN 1
      ELSE 0
    END
  ) AS rtv_step_3,
  --if they have any of the following steps, they made it to step 4
  MAX(
    CASE
      WHEN pb.event_name IN (
        'step-4',
        'ineligible',
        'under-18',
        'register-ovr'
      ) THEN 1
      ELSE 0
    END
  ) AS rtv_step_4,
  --if they have any of the following steps, they made it to step 3 or 4
  MAX(
    CASE
      WHEN pb.event_name IN (
        'step-3',
        'step-4',
        'ineligible',
        'under-18',
        'register-OVR',
        'register-form'
      ) THEN 1
      ELSE 0
    END
  ) AS rtv_step_3_or_4,
  --if they have a registration event THEN they registered
  MAX(COALESCE(pb.registered, 0)) AS registered
FROM
  session_base sb
  JOIN funnel_base fb
  ON (
    sb.device_id = fb.device_id
    AND sb.session_id = fb.session_id
  ) FULL
  OUTER JOIN post_base pb
  ON (
    sb.northstar_id = pb.northstar_id
    AND pb.event_ts > fb.event_datetime
  )
GROUP BY
  sb.session_id,
  sb.device_id,
  COALESCE(COALESCE(sb.northstar_id, pb.northstar_id)),
  pb.post_id
