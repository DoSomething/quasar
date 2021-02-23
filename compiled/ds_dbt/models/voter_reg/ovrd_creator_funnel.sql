--drop table analyst_sandbox.es_ovrd_creator_funnel
--create table analyst_sandbox.es_ovrd_creator_funnel as
WITH funnel_base AS (
  --Unique combinations of device_id, session_id, northstar_id
  SELECT
    psc.session_id,
    psc.landing_datetime,
    psc.ending_datetime,
    psc.device_id,
    pec.northstar_id,
    pec."path",
    pec.event_name,
    pec.event_datetime,
    psc.session_utm_campaign,
    psc.session_referrer_host
  FROM
    "quasar_prod_warehouse"."public"."snowplow_raw_events"
    pec
    JOIN "quasar_prod_warehouse"."public"."snowplow_sessions"
    psc
    ON (
      pec.session_id = psc.session_id
      AND pec.device_id = psc.device_id
    ) --Filter to URL of interest
  WHERE
    pec."path" ILIKE '%online-registration-drive%'
    AND psc.landing_datetime >= '2020-03-01'
    AND pec.event_datetime >= '2020-03-01' --Filter to events of interest
    AND pec.event_name IN (
      'phoenix_clicked_share_snapchat',
      'phoenix_clicked_copy_to_clipboard',
      'phoenix_clicked_share_facebook',
      'phoenix_clicked_share_email',
      'phoenix_clicked_share_facebook_messenger',
      'phoenix_clicked_share_twitter',
      'phoenix_clicked_signup',
      'phoenix_completed_signup',
      'phoenix_clicked_voter_registration_action',
      'phoenix_opened_modal',
      'visit',
      'view'
    )
),
northstars AS (
  --Authenticated Users
  SELECT
    device_id,
    northstar_id,
    session_id
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
    n.northstar_id IS NULL
  GROUP BY
    1,
    2
),
session_base AS (
  --Authenticated Sessions
  --Joining with users table to eliminate internal (dosomething.org) northstar_ids
  SELECT
    n.session_id,
    n.device_id,
    n.northstar_id
  FROM
    northstars n
    JOIN "quasar_prod_warehouse"."public"."users"
    u
    ON (
      n.northstar_id = u.northstar_id
    )
  UNION ALL
    --Anonymous Sessions
  SELECT
    d.session_id,
    d.device_id,
    NULL
  FROM
    devices d
),
creations AS (
  --Signups represent the creation of the drive
  SELECT
    northstar_id,
    id AS signup_id,
    created_at
  FROM
    "quasar_prod_warehouse"."public"."signups" s
  WHERE
    campaign_id = '9054'
    AND source_bucket = 'web'
    AND s.created_at >= '2020-03-01'
),
starts AS (
  --There seem to be a few cases of multiple posts per northstar
  SELECT
    p.northstar_id,
    p.id AS post_id,
    p.status,
    p.created_at,
    rock.started_registration_utc
  FROM
    "quasar_prod_warehouse"."public"."posts"
    p
    LEFT JOIN "quasar_prod_warehouse"."public"."rock_the_vote"
    rock
    ON (
      rock.post_id = p.id
    )
  WHERE
    p.vr_source = 'web'
    AND p."type" = 'voter-reg'
    AND p.vr_source_details LIKE '%OnlineRegistrationDrive%'
    AND p.created_at >= '2020-03-01' --Only registrations with these tracking sources represent completing the funnel
    --Excluding Groups which look like -> source_details:[group_name]OnlineRegistrationDrive_Affirmation
    AND rock.tracking_source LIKE '%source_details:OnlineRegistrationDrive_affirmation%'
    AND p.group_id IS NULL
),
registrations AS (
  --There seem to be a few cases of multiple registrations per northstar
  SELECT
    r.northstar_id,
    r.post_id,
    rtv.started_registration_utc
  FROM
    "quasar_prod_warehouse"."public"."reportbacks"
    r
    LEFT JOIN "quasar_prod_warehouse"."public"."rock_the_vote"
    rtv
    ON (
      rtv.post_id = r.post_id
    )
  WHERE
    r.vr_source = 'web'
    AND r.post_bucket = 'voter_registrations'
    AND r.vr_source_details LIKE 'OnlineRegistrationDrive%'
    AND r.post_created_at >= '2020-01-01' --Excluding Groups which look like -> source_details:[group_name]OnlineRegistrationDrive_Affirmation
    AND rtv.tracking_source LIKE '%source_details:OnlineRegistrationDrive_affirmation%'
    AND rtv.tracking_source NOT LIKE '%group_id%'
    AND r.group_id IS NULL
),
referral_counts AS (
  --Get referral counts
  SELECT
    --Prefer referrer_user_id ON post, extract value FROM tracking source for legacy posts
    COALESCE(
      p.referrer_user_id,
      SPLIT_PART(
        SUBSTRING(
          rtv.tracking_source
          FROM
            'user\:(.+)\,'
        ),
        ',',
        1
      )
    ) AS referrer,
    COUNT(*) AS referrals_start,
    SUM(
      CASE
        WHEN rtv.status = 'Complete' THEN 1
        ELSE 0
      END
    ) AS referrals_completed
  FROM
    "quasar_prod_warehouse"."public"."posts"
    p
    JOIN "quasar_prod_warehouse"."public"."rock_the_vote"
    rtv
    ON (
      p.id = rtv.post_id
    )
  WHERE
    rtv.tracking_source ILIKE '%source_details:onlinedrivereferral%' --Must be referral
    AND rtv.tracking_source ILIKE '%referral=true%' --Exclude groups
    AND rtv.tracking_source NOT LIKE '%group_id%'
    AND p.group_id IS NULL --Exclude nonsense or empty nsid values
    AND COALESCE(
      p.referrer_user_id,
      SPLIT_PART(
        SUBSTRING(
          rtv.tracking_source
          FROM
            'user\:(.+)\,'
        ),
        ',',
        1
      )
    ) NOT IN (
      '{userId}',
      'null',
      ''
    )
    AND p.created_at >= '2020-03-01'
  GROUP BY
    COALESCE(
      p.referrer_user_id,
      SPLIT_PART(
        SUBSTRING(
          rtv.tracking_source
          FROM
            'user\:(.+)\,'
        ),
        ',',
        1
      )
    )
),
funnel AS (
  SELECT
    sb.session_id,
    sb.device_id,
    sb.northstar_id,
    ROW_NUMBER() over(
      PARTITION BY sb.northstar_id
      ORDER BY
        MIN(
          C.signup_id
        )
    ) AS nth_drive,
    --The signup represents the creation of the drive
    MIN(
      C.signup_id
    ) AS signup_id,
    --If the referrer does in fact register to vote, this is the corresponding reportback
    MIN(
      reg.post_id
    ) AS post_id,
    --Earliest recorded page visit
    MIN(
      fb.event_datetime
    ) AS journey_begin_ts,
    --Earliest campaign signup (drive creation)
    MIN(
      C.created_at
    ) AS drive_creation_ts,
    --Latest registration timestamp for northstar
    MAX(
      reg.started_registration_utc
    ) AS latest_register_ts,
    --Latest start RTV process for northstar
    MAX(
      po.started_registration_utc
    ) AS latest_get_started_ts,
    --Did they visit? Includes other event types to account for missing visits in puck
    MAX(
      CASE
        WHEN fb.session_utm_campaign ILIKE '%niche%' THEN 'niche'
        WHEN fb.session_utm_campaign ILIKE '%fastweb%' THEN 'fastweb'
        WHEN fb.session_referrer_host ILIKE '%dosomething%' THEN 'dosomething'
        ELSE 'other'
      END
    ) AS traffic_source,
    MAX(
      CASE
        WHEN fb.event_name IN (
          'visit',
          'view',
          'phoenix_clicked_signup',
          'phoenix_clicked_voter_registration_action'
        ) THEN 1
        ELSE 0
      END
    ) AS page_visit,
    --Funnel flags
    MAX(
      CASE
        WHEN fb.northstar_id IS NOT NULL THEN 1
        ELSE 0
      END
    ) AS authenticated,
    MAX(
      CASE
        WHEN fb.event_name = 'phoenix_clicked_signup' THEN 1
        ELSE 0
      END
    ) AS click_join_us,
    MAX(
      CASE
        WHEN C.signup_id IS NOT NULL THEN 1
        ELSE 0
      END
    ) AS completed_signup,
    MAX(
      CASE
        WHEN fb.event_name = 'phoenix_clicked_voter_registration_action' THEN 1
        ELSE 0
      END
    ) AS click_start_registration,
    MAX(
      CASE
        WHEN po.post_id IS NOT NULL THEN 1
        ELSE 0
      END
    ) AS clicked_get_started,
    MAX(
      CASE
        WHEN po.status IN (
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
    MAX(
      CASE
        WHEN po.status IN (
          'step-3',
          'ineligible',
          'under-18',
          'register-form'
        ) THEN 1
        ELSE 0
      END
    ) AS rtv_step_3,
    MAX(
      CASE
        WHEN po.status IN (
          'step-4',
          'ineligible',
          'under-18',
          'register-OVR'
        ) THEN 1
        ELSE 0
      END
    ) AS rtv_step_4,
    MAX(
      CASE
        WHEN po.status IN (
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
    MAX(
      CASE
        WHEN reg.northstar_id IS NOT NULL THEN 1
        ELSE 0
      END
    ) AS registered,
    MAX(
      CASE
        WHEN fb.event_name = 'phoenix_clicked_copy_to_clipboard' THEN 1
        ELSE 0
      END
    ) AS click_copy_link,
    MAX(
      CASE
        WHEN fb.event_name IN (
          'phoenix_clicked_share_facebook',
          'phoenix_clicked_share_email',
          'phoenix_clicked_share_facebook_messenger',
          'phoenix_clicked_share_twitter',
          'phoenix_clicked_share_snapchat'
        ) THEN 1
        ELSE 0
      END
    ) AS clicked_any_share,
    MAX(
      CASE
        WHEN fb.event_name = 'phoenix_clicked_share_facebook' THEN 1
        ELSE 0
      END
    ) AS clicked_share_fb,
    MAX(
      CASE
        WHEN fb.event_name = 'phoenix_clicked_share_email' THEN 1
        ELSE 0
      END
    ) AS clicked_share_email,
    MAX(
      CASE
        WHEN fb.event_name = 'phoenix_clicked_share_facebook_messenger' THEN 1
        ELSE 0
      END
    ) AS clicked_share_fb_msgr,
    MAX(
      CASE
        WHEN fb.event_name = 'phoenix_clicked_share_twitter' THEN 1
        ELSE 0
      END
    ) AS clicked_share_twitter,
    MAX(
      CASE
        WHEN fb.event_name = 'phoenix_clicked_share_snapchat' THEN 1
        ELSE 0
      END
    ) AS clicked_share_snapchat
  FROM
    session_base sb
    JOIN funnel_base fb
    ON (
      sb.session_id = fb.session_id
      AND sb.device_id = fb.device_id
    ) --Join Drive creations (allow a bit of )
    LEFT JOIN creations C
    ON (
      sb.northstar_id = C.northstar_id
      AND C.created_at BETWEEN fb.landing_datetime - INTERVAL '15 minute'
      AND fb.ending_datetime + INTERVAL '15 minute'
    ) --Join started AND completed registrations
    LEFT JOIN starts po
    ON (
      sb.northstar_id = po.northstar_id
      AND po.started_registration_utc BETWEEN fb.landing_datetime
      AND fb.ending_datetime + INTERVAL '15 minute'
    )
    LEFT JOIN registrations reg
    ON (
      sb.northstar_id = reg.northstar_id
      AND reg.started_registration_utc BETWEEN fb.landing_datetime
      AND fb.ending_datetime + INTERVAL '15 minute'
    )
  GROUP BY
    sb.session_id,
    sb.device_id,
    sb.northstar_id --Only consider folks who did at least one of the below
  HAVING
    MAX(
      CASE
        WHEN fb.event_name IN (
          'visit',
          'view',
          'phoenix_clicked_signup',
          'phoenix_clicked_voter_registration_action'
        ) THEN 1
        ELSE 0
      END
    ) = 1
)
SELECT
  f.session_id,
  f.device_id,
  f.northstar_id,
  f.signup_id,
  f.nth_drive,
  f.post_id,
  journey_begin_ts,
  drive_creation_ts,
  latest_register_ts,
  latest_get_started_ts,
  traffic_source,
  page_visit,
  click_join_us,
  authenticated,
  completed_signup,
  click_start_registration,
  clicked_get_started,
  rtv_step_2,
  rtv_step_3,
  rtv_step_4,
  rtv_step_3_or_4,
  registered,
  click_copy_link,
  clicked_any_share,
  clicked_share_fb,
  clicked_share_email,
  clicked_share_fb_msgr,
  clicked_share_twitter,
  clicked_share_snapchat,
  rc.referrals_start,
  rc.referrals_completed
FROM
  funnel f
  LEFT JOIN referral_counts rc
  ON (
    f.northstar_id = rc.referrer
    AND f.nth_drive = 1
  )