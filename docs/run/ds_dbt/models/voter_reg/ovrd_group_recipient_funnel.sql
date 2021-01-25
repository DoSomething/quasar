

  create  table "quasar"."public"."ovrd_group_recipient_funnel__dbt_tmp"
  as (
    WITH funnel_base AS (
  SELECT
    pec.session_id,
    pec.device_id,
    pec.northstar_id,
    pec.event_name,
    pec.event_datetime,
    SUBSTRING(
      pec.query_parameters
      FROM
        'group_id=([0-9]+)'
    ) AS group_id
  FROM
    "quasar"."public"."snowplow_raw_events"
    pec
    JOIN "quasar"."public"."snowplow_sessions"
    psc
    ON (
      pec.session_id = psc.session_id
    ) --filter the url of interest
  WHERE
    pec."path" ILIKE '%my-voter-registration-drive%'
    AND pec.event_datetime >= '2020-08-01'
),
northstars AS (
  --Authenticated Users
  SELECT
    device_id,
    session_id,
    northstar_id,
    group_id
  FROM
    funnel_base
  WHERE
    northstar_id IS NOT NULL
    AND group_id IS NOT NULL GROUP BY 1,
    2,
    3,
    4
),
devices AS (
  --Anonymous Users (removes cases of sessions that started anonymous AND got autheticated afterwards)
  SELECT
    b.device_id,
    b.session_id,
    b.group_id
  FROM
    funnel_base b
    LEFT JOIN northstars n
    ON (
      b.session_id = n.session_id
      AND b.device_id = n.device_id
    )
  WHERE
    n.session_id IS NULL
    AND b.group_id IS NOT NULL GROUP BY 1,
    2,
    3
),
session_base AS (
  --Authenticated Sessions
  --Joining with users table to eliminate internal (dosomething.org) northstar_ids
  SELECT
    f.device_id,
    f.session_id,
    f.northstar_id,
    f.group_id
  FROM
    funnel_base f
    JOIN northstars n
    ON (
      f.session_id = n.session_id
    )
    JOIN PUBLIC.users u
    ON (
      f.northstar_id = u.northstar_id
    )
  UNION ALL
    --Anonymous Sessions
  SELECT
    f.device_id,
    f.session_id,
    NULL,
    f.group_id
  FROM
    funnel_base f
    JOIN devices d
    ON (
      f.device_id = d.device_id
      AND f.session_id = d.session_id
    )
),
post_base AS (
  --uniON rtv process starts who came FROM a referral per their tracking source
  SELECT
    p.northstar_id,
    rtv.started_registration_utc AS event_ts,
    p.status AS event_name,
    SUBSTRING(
      rtv.tracking_source
      FROM
        'group_id=([0-9]+)'
    ) AS group_id,
    r.post_id,
    CASE
      WHEN r.post_id IS NOT NULL THEN 1
    END AS registered
  FROM
    "quasar"."public"."posts"
    p
    JOIN "quasar"."public"."rock_the_vote"
    rtv
    ON p.id = rtv.post_id
    LEFT JOIN "quasar"."public"."reportbacks"
    r
    ON p.id = r.post_id
  WHERE
    p.vr_source_details LIKE '%onlinedrivereferral%'
    AND rtv.tracking_source LIKE '%onlinedrivereferral%group_id%referral=true%'
    AND p.created_at >= '2020-06-01'
),
--collapse the event log to a user level table with flags AND timestamps
funnel AS (
  SELECT
    sb.session_id,
    sb.device_id,
    COALESCE(
      sb.northstar_id,
      pb.northstar_id
    ) AS northstar_id,
    COALESCE(
      sb.group_id,
      pb.group_id
    ) AS group_id,
    pb.post_id,
    --earliest ts ON record is when their journey began
    MIN(COALESCE(fb.event_datetime, pb.event_ts)) AS journey_begin_ts,
    --you must have visited the page if you are in the event log (allows us to 'backfill' some of the missing info
    1 AS page_visit,
    --earliest rtv record for the user is when they began registering
    MIN(
      pb.event_ts
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
    --if they have a registratiON event THEN they registered
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
    COALESCE(
      sb.northstar_id,
      pb.northstar_id
    ),
    COALESCE(
      sb.group_id,
      pb.group_id
    ),
    pb.post_id
)
SELECT
  session_id,
  northstar_id,
  device_id,
  group_id,
  gt.name AS group_name,
  post_id,
  journey_begin_ts,
  page_visit,
  started_register_ts,
  clicked_get_started,
  rtv_step_2,
  rtv_step_3,
  rtv_step_4,
  rtv_step_3_or_4,
  registered
FROM
  funnel f
  LEFT JOIN "quasar"."public"."groups"
  g
  ON (
    f.group_id = g.id :: text
  )
  LEFT JOIN "quasar"."public"."group_types"
  gt
  ON (
    g.group_type_id = gt.id
  )
  );