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
    {{ ref('snowplow_raw_events') }}
    pec
    JOIN {{ ref('snowplow_sessions') }}
    psc
    ON (
      pec.session_id = psc.session_id
      AND pec.device_id = psc.device_id
    ) --Filter to URL of interest
  WHERE
    pec."path" ILIKE '%online-voter-registration-drives%'
    AND psc.landing_datetime >= '2020-06-01'
    AND pec.event_datetime >= '2020-06-01' --Filter to events of interest
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
  --Anonymous Users (removes cases of sessions that started anonymous and got autheticated afterwards)
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
  --Joining with users table to eliminate internal (dosomething.org) northstar_ids
  SELECT
    n.session_id,
    n.device_id,
    n.northstar_id
  FROM
    northstars n
    JOIN {{ ref('users') }}
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
    s.id AS signup_id,
    s.created_at,
    s.group_id --, s.campaign_id, c.campaign_cause, c.campaign_name, c.campaign_run_start_date
  FROM
    {{ ref('signups') }}
    s
    JOIN {{ ref('campaign_info') }} C
    ON (
      s.campaign_id = C.campaign_id :: text
    )
  WHERE
    s.source_bucket = 'web'
    AND C.campaign_cause = 'voter-registration'
    AND C.campaign_name LIKE '%Online%Drives 2020%'
    AND s.group_id IS NOT NULL
    AND s.created_at >= '2020-06-01'
),
starts AS (
  --There seem to be a few cases of multiple posts per northstar
  SELECT
    p.northstar_id,
    p.id AS post_id,
    p.status,
    rock.started_registration_utc,
    rock.tracking_source
  FROM
    {{ ref('posts') }}
    p
    LEFT JOIN {{ ref('rock_the_vote') }}
    rock
    ON (
      rock.post_id = p.id
    )
  WHERE
    p.vr_source = 'web'
    AND p."type" = 'voter-reg'
    AND p.created_at >= '2020-06-01' --Only registrations with these tracking sources represent starting the funnel
    AND rock.tracking_source LIKE '%OnlineRegistrationDrive_Affirmation%' --don't use any group_id filters because they're not flowing into the data
    --AND p.group_id is not null
),
registrations AS (
  --There seem to be a few cases of multiple registrations per northstar (12 northstars -- 11 have 2 registrations and 1 has 3 for a total of 25 registrations)
  SELECT
    r.northstar_id,
    r.post_id,
    rock.started_registration_utc,
    rock.tracking_source --row_number() over(partition by r.northstar order by rock.started_registration_utc desc) as nth_registration
  FROM
    {{ ref('reportbacks') }}
    r
    LEFT JOIN {{ ref('rock_the_vote') }}
    rock
    ON (
      rock.post_id = r.post_id
    )
  WHERE
    r.vr_source = 'web'
    AND r.post_bucket = 'voter_registrations'
    AND r.vr_source_details LIKE '%OnlineRegistrationDrive%'
    AND r.post_created_at >= '2020-06-01' --Only registrations with these tracking sources represent completing the funnel
    AND rock.tracking_source LIKE '%OnlineRegistrationDrive_Affirmation%' --don't use any group filters because they're not flowing into the data
),
referral_counts AS (
  --Get referral counts
  SELECT
    --Prefer referrer_user_id on post, extract value FROM tracking source for legacy posts
    COALESCE(
      p.referrer_user_id,
      SPLIT_PART(
        SUBSTRING(
          tracking_source
          FROM
            'user\:(.+)\,'
        ),
        ',',
        1
      )
    ) AS referrer,
    --Group ID is not always populated in Post so we extract it FROM RTV
    SUBSTRING(
      rtv.tracking_source
      FROM
        'group_id=(.+)\,'
    ) AS group_id,
    COUNT(*) AS referrals_start,
    SUM(
      CASE
        WHEN rtv.status = 'Complete' THEN 1
        ELSE 0
      END
    ) AS referrals_completed
  FROM
    {{ ref('posts') }}
    p
    JOIN {{ ref('rock_the_vote') }}
    rtv
    ON (
      p.id = rtv.post_id
    )
  WHERE
    --Must be referral
    rtv.tracking_source LIKE '%onlinedrivereferral%group_id%referral=true%' --Exclude nonsense or empty nsid values
    AND COALESCE(
      p.referrer_user_id,
      SPLIT_PART(
        SUBSTRING(
          tracking_source
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
    AND p.created_at >= '2020-06-01'
  GROUP BY
    1,
    2
),
funnel AS (
  SELECT
    sb.session_id,
    sb.device_id,
    sb.northstar_id,
    C.group_id,
    --The signup represents the creation of the drive
    MIN(
      C.signup_id
    ) AS signup_id,
    COUNT(
      DISTINCT C.signup_id
    ) AS num_drives,
    --We rank the signups per group in case there are multiple signups per group (so we only assign referrals to the first signup)
    ROW_NUMBER() over(
      PARTITION BY sb.northstar_id,
      C.group_id
      ORDER BY
        MIN(
          C.signup_id
        )
    ) AS nth_drive,
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
        WHEN fb.northstar_id IS NOT NULL THEN 1
        ELSE 0
      END
    ) AS authenticated,
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
          'phoenix_clicked_share_action_facebook',
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
    ) --Join Drive creations
    LEFT JOIN creations C
    ON (
      sb.northstar_id = C.northstar_id
      AND C.created_at BETWEEN fb.landing_datetime
      AND fb.ending_datetime
    ) --Join reportbacks to determine if they registered via the source we care about
    LEFT JOIN registrations reg
    ON (
      sb.northstar_id = reg.northstar_id
      AND reg.started_registration_utc BETWEEN fb.landing_datetime
      AND fb.ending_datetime + INTERVAL '20 minute'
    )
    LEFT JOIN starts po
    ON (
      sb.northstar_id = po.northstar_id
      AND po.started_registration_utc BETWEEN fb.landing_datetime
      AND fb.ending_datetime + INTERVAL '20 minute'
    )
  GROUP BY
    sb.session_id,
    sb.device_id,
    sb.northstar_id,
    C.group_id --Only consider folks who did at least one of the below on the URL of interest
  HAVING
    MAX(
      CASE
        WHEN fb.event_name IN (
          'visit',
          'view',
          'phoenix_clicked_signup',
          'phoenix_completed_signup',
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
  f.group_id,
  gt.name AS group_name,
  f.num_drives,
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
    AND f.group_id :: text = rc.group_id
    AND f.nth_drive = 1
  )
  LEFT JOIN {{ ref('groups') }}
  g
  ON (
    f.group_id = g.id
  )
  LEFT JOIN {{ ref('group_types') }}
  gt
  ON (
    g.group_type_id = gt.id
  )
