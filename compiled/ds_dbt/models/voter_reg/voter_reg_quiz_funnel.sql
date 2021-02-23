--This code simplifies the multiple steps that anonymous users AND members take IN the Voter-Registration Quiz
--which lauched IN dosomething.org IN Jan-2020
--Each row is a unique combination of device_id, session_id, northstar_id AND post_id.
-- A northstar_id can be null AND CASEs LIKE this, represent anonymous sessions WHERE no user was auTHENticated.
-- A device_id - session_id combination that has been associated with one or multiple northstar_ids is not present again AS an anonymous session even if the start of the session was anonymous AND got auTHENticated later on.
-- A device_id can be present multiple times associated with both a northstar_id AND a null northstar_id, across different sessions
-- There are 457 device_id, session_id, northstar_id combinations that repeat because the same auTHENticated session session was mapped to multiple post_ids (registration events)
--The registration event identified AS a reportback with vr_source='web' AND vr_source_details LIKE '%VoterRegQuiz%' is mapped to the quiz funnel by northstar_id AND timestamp
--(start of the registration occurring within the session, extending the session-end for an additional 15 minutes).
--Restricting the registration event to occur exactly within the web session start/end times was resulting IN a drop of about 1/2 of the registrations.
--Extending the session for over 15 minutes was not increasing the number of mapped registrations but was making more registrations to get mapped to more than one session.
--Mapping of registrations to multiple sessions could not be completely eliminated but was reduced to a minimum (161 or 0.05%) AS of Aug 1, 2020.
WITH funnel_base AS (
  --Unique combinations of device_id, session_id, northstar_id
  SELECT
    pec.device_id,
    pec.northstar_id,
    pec.session_id
  FROM
    "quasar_prod_warehouse"."public"."snowplow_raw_events"
    pec
    JOIN "quasar_prod_warehouse"."public"."snowplow_sessions"
    psc
    ON (
      pec.session_id = psc.session_id
    ) --URL of the VR quiz funnel
  WHERE
    (
      pec."path" ILIKE '%ready-vote'
      OR pec."path" ILIKE '%ready-vote/%'
    )
    AND pec.event_datetime >= '2020-01-01'
  GROUP BY
    pec.device_id,
    pec.northstar_id,
    pec.session_id
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
    n.session_id IS NULL
  GROUP BY
    1,
    2
),
session_base AS (
  --Authenticated Sessions
  --Joining with users table to eliminate internal (dosomething.org) northstar_ids
  SELECT
    f.device_id,
    f.northstar_id,
    f.session_id
  FROM
    funnel_base f
    JOIN northstars n
    ON (
      f.session_id = n.session_id
    )
    JOIN "quasar_prod_warehouse"."public"."users"
    u
    ON (
      f.northstar_id = u.northstar_id
    )
  UNION ALL
    --Anonymous Sessions
  SELECT
    f.device_id,
    NULL,
    f.session_id
  FROM
    funnel_base f
    JOIN devices d
    ON (
      f.session_id = d.session_id
    )
),
reg_started AS (
  SELECT
    p.northstar_id,
    p.id AS post_id,
    rtv.started_registration_utc AS started_registration,
    rtv.tracking_source,
    rtv.status
  FROM
    "quasar_prod_warehouse"."public"."posts"
    p
    LEFT JOIN "quasar_prod_warehouse"."public"."rock_the_vote"
    rtv
    ON (
      p.id = rtv.post_id
      AND rtv.status IS NOT NULL
    )
  WHERE
    p.vr_source = 'web'
    AND p.vr_source_details LIKE '%VoterRegQuiz%'
    AND p.created_at >= '2020-01-01'
),
reg_completed AS (
  --Registration events coming FROM web-based quiz
  SELECT
    r.northstar_id,
    r.post_id,
    rtv.tracking_source,
    --r.post_created_at appears to be the UTC conversion of rock.started_registration
    rtv.started_registration_utc AS started_registration
  FROM
    "quasar_prod_warehouse"."public"."reportbacks"
    r
    LEFT JOIN "quasar_prod_warehouse"."public"."rock_the_vote"
    rtv
    ON r.post_id = rtv.post_id
  WHERE
    r.post_bucket = 'voter_registrations'
    AND r.vr_source = 'web'
    AND r.vr_source_details LIKE '%VoterRegQuiz%'
    AND r.post_created_at >= '2020-01-01'
),
funnel_landing AS (
  --The top of the funnel does not require authentication
  --Pulling date AND creating yes/no flags for the initial 2 steps
  SELECT
    pec.device_id,
    pec.session_id,
    MIN(
      psc.landing_datetime
    ) AS session_landing_datetime,
    MAX(
      psc.ending_datetime
    ) AS session_ending_datetime,
    --Earliest page visit
    MIN(
      pec.event_datetime
    ) AS journey_begin_ts,
    --Create traffic source groupings
    --TBD: maybe later we can create additional groups (social, search, etc)
    MAX(
      CASE
        -- prev known as page_utm_campaign
        WHEN pec.utm_campaign ILIKE '%niche%' THEN 'niche'
        -- prev known as page_utm_campaign
        WHEN pec.utm_campaign ILIKE '%fastweb%' THEN 'fastweb'
        WHEN psc.session_referrer_host ILIKE '%dosomething%' THEN 'dosomething'
        ELSE 'other'
      END
    ) AS traffic_source,
    MAX(
      CASE
        WHEN pec.event_name IN (
          'visit',
          'view',
          'phoenix_clicked_signup',
          'phoenix_clicked_voter_registration_action'
        ) THEN 1
        ELSE 0
      END
    ) AS page_visit,
    MAX(
      CASE
        WHEN pec.event_name = 'phoenix_clicked_signup' THEN 1
        ELSE 0
      END
    ) AS click_join_us
  FROM
    "quasar_prod_warehouse"."public"."snowplow_raw_events"
    pec
    JOIN "quasar_prod_warehouse"."public"."snowplow_sessions"
    psc
    ON (
      pec.session_id = psc.session_id
    ) --URL of the VR quiz funnel
  WHERE
    pec."path" ILIKE '%ready-vote%'
    AND pec.event_datetime >= '2020-01-01'
  GROUP BY
    pec.device_id,
    pec.session_id
),
funnel_auth AS (
  --The next steps of the funnel do require auTHENtication
  --Pulling date AND creating yes/no flags for the following steps
  SELECT
    pec.session_id,
    pec.northstar_id,
    rc.post_id,
    --Earliest page visit
    MIN(
      pec.event_datetime
    ) AS journey_begin_ts,
    --Latest click to rock the vote page event
    MAX(
      pec.event_datetime
    ) filter(
      WHERE
        pec.event_name = 'phoenix_clicked_voter_registration_action'
    ) AS max_click_registration_ts,
    --latest quiz submission
    MAX(
      pec.event_datetime
    ) filter(
      WHERE
        pec.event_name = 'phoenix_submitted_quiz'
    ) AS max_submit_quiz_ts,
    --latest registration timestamp
    MAX(
      rs.started_registration
    ) AS latest_register_ts,
    --latest registration start timestamp
    MAX(
      rc.started_registration
    ) AS latest_get_started_ts,
    --latest submit photo timestamp
    MAX(
      pec.event_datetime
    ) filter(
      WHERE
        pec.event_name IN (
          'phoenix_failed_post_request',
          'phoenix_completed_post_request',
          'phoenix_found_post_request',
          'phoenix_submitted_photo_submission_action',
          'phoenix_completed_photo_submission_action',
          'phoenix_failed_photo_submission_action'
        )
    ) AS max_submit_photo_ts,
    --Latest FB share timestamp
    MAX(
      pec.event_datetime
    ) filter(
      WHERE
        pec.event_name = 'phoenix_clicked_share_action_facebook'
    ) AS max_fb_share_ts,
    MAX(
      CASE
        WHEN pec.northstar_id IS NOT NULL THEN 1
        ELSE 0
      END
    ) AS authenticated,
    MAX(
      CASE
        WHEN pec.event_name = 'phoenix_clicked_voter_registration_action' THEN 1
        ELSE 0
      END
    ) AS click_start_registration,
    MAX(
      CASE
        WHEN rs.post_id IS NOT NULL THEN 1
        ELSE 0
      END
    ) AS clicked_get_started,
    MAX(
      CASE
        WHEN rs.status IN (
          'Step 2',
          'Step 3',
          'Step 4',
          'Rejected',
          'Under 18',
          'Complete'
        )
        AND rs.tracking_source ILIKE '%VoterRegQuiz_Affirmation%' THEN 1
        ELSE 0
      END
    ) AS rtv_step_2_affirmation,
    MAX(
      CASE
        WHEN rs.status IN (
          'Step 2',
          'Step 3',
          'Step 4',
          'Rejected',
          'Under 18',
          'Complete'
        )
        AND rs.tracking_source ILIKE '%VoterRegQuiz_completed%' THEN 1
        ELSE 0
      END
    ) AS rtv_step_2_quizcomplete,
    MAX(
      CASE
        WHEN rs.status IN (
          'Step 3',
          'Step 4',
          'Rejected',
          'Under 18',
          'Complete'
        )
        AND rs.tracking_source ILIKE '%VoterRegQuiz_Affirmation%' THEN 1
        ELSE 0
      END
    ) AS rtv_step_3_affirmation,
    MAX(
      CASE
        WHEN rs.status IN (
          'Step 3',
          'Step 4',
          'Rejected',
          'Under 18',
          'Complete'
        )
        AND rs.tracking_source ILIKE '%VoterRegQuiz_completed%' THEN 1
        ELSE 0
      END
    ) AS rtv_step_3_quizcomplete,
    MAX(
      CASE
        WHEN rs.status IN (
          'Step 4',
          'Rejected',
          'Under 18',
          'Complete'
        )
        AND rs.tracking_source ILIKE '%VoterRegQuiz_Affirmation%' THEN 1
        ELSE 0
      END
    ) AS rtv_step_4_affirmation,
    MAX(
      CASE
        WHEN rs.status IN (
          'Step 4',
          'Rejected',
          'Under 18',
          'Complete'
        )
        AND rs.tracking_source ILIKE '%VoterRegQuiz_completed%' THEN 1
        ELSE 0
      END
    ) AS rtv_step_4_quizcomplete,
    MAX(
      CASE
        WHEN rs.status IN (
          'Step 3',
          'Step 4',
          'Rejected',
          'Under 18',
          'Complete'
        )
        AND rs.tracking_source ILIKE '%VoterRegQuiz_Affirmation%' THEN 1
        ELSE 0
      END
    ) AS rtv_step_3_or_4_affirmation,
    MAX(
      CASE
        WHEN rs.status IN (
          'Step 3',
          'Step 4',
          'Rejected',
          'Under 18',
          'Complete'
        )
        AND rs.tracking_source ILIKE '%VoterRegQuiz_completed%' THEN 1
        ELSE 0
      END
    ) AS rtv_step_3_or_4_quizcomplete,
    MAX(
      CASE
        WHEN rs.post_id IS NOT NULL
        AND rs.tracking_source ILIKE '%VoterRegQuiz_Affirmation%' THEN 1
        ELSE 0
      END
    ) AS clicked_get_started_affirmation,
    MAX(
      CASE
        WHEN rs.post_id IS NOT NULL
        AND rs.tracking_source ILIKE '%VoterRegQuiz_completed%' THEN 1
        ELSE 0
      END
    ) AS clicked_get_started_quizcomplete,
    MAX(
      CASE
        WHEN rc.northstar_id IS NOT NULL THEN 1
        ELSE 0
      END
    ) AS registered,
    MAX(
      CASE
        WHEN rc.northstar_id IS NOT NULL
        AND rc.tracking_source ILIKE '%VoterRegQuiz_completed%' THEN 1
        ELSE 0
      END
    ) AS registered_quizcomplete,
    MAX(
      CASE
        WHEN rc.northstar_id IS NOT NULL
        AND rc.tracking_source ILIKE '%VoterRegQuiz_Affirmation%' THEN 1
        ELSE 0
      END
    ) AS registered_affirmation,
    MAX(
      CASE
        WHEN pec.event_name = 'phoenix_clicked_share_action_facebook' THEN 1
        ELSE 0
      END
    ) AS clicked_share_fb,
    MAX(
      CASE
        WHEN pec.event_name = 'phoenix_submitted_quiz' THEN 1
        ELSE 0
      END
    ) AS submitted_quiz,
    MAX(
      CASE
        WHEN pec.event_name IN (
          'phoenix_failed_post_request',
          'phoenix_completed_post_request',
          'phoenix_found_post_request',
          'phoenix_submitted_photo_submission_action',
          'phoenix_completed_photo_submission_action',
          'phoenix_failed_photo_submission_action'
        ) THEN 1
        ELSE 0
      END
    ) AS clicked_submit_photo
  FROM
    "quasar_prod_warehouse"."public"."snowplow_raw_events"
    pec
    JOIN "quasar_prod_warehouse"."public"."snowplow_sessions"
    psc
    ON (
      pec.session_id = psc.session_id
    ) --Join northstar/session with voter reg activity FROM posts AND reportbacks
    LEFT JOIN reg_started rs
    ON (
      rs.northstar_id = pec.northstar_id
      AND rs.started_registration BETWEEN psc.landing_datetime
      AND (
        psc.ending_datetime + INTERVAL '15 minute'
      )
    )
    LEFT JOIN reg_completed rc
    ON (
      rc.northstar_id = pec.northstar_id
      AND rc.started_registration BETWEEN psc.landing_datetime
      AND (
        psc.ending_datetime + INTERVAL '15 minute'
      )
    )
  WHERE
    --URL of the VR quiz funnel
    (
      pec."path" ILIKE '%ready-vote'
      OR pec."path" ILIKE '%ready-vote/%'
    )
    AND pec.northstar_id IS NOT NULL
    AND pec.event_datetime >= '2020-01-01'
  GROUP BY
    pec.session_id,
    pec.northstar_id,
    rc.post_id
) --We SELECT unique rows because some sessions are used by different northstar_id and this creates a multiplier effect WHEN joining funnel_landing and funnel_auth
SELECT
  DISTINCT s.device_id,
  s.northstar_id,
  s.session_id,
  fl.session_landing_datetime,
  fl.session_ending_datetime,
  fl.journey_begin_ts AS journey_begin_ts,
  fa.journey_begin_ts AS journey_begin_ts_northstar,
  fa.post_id,
  fa.max_click_registration_ts,
  fa.max_submit_quiz_ts,
  fa.latest_register_ts,
  fa.latest_get_started_ts,
  fa.max_submit_photo_ts,
  fa.max_fb_share_ts,
  fl.traffic_source,
  fl.page_visit,
  fl.click_join_us,
  fa.authenticated,
  fa.click_start_registration,
  fa.clicked_get_started,
  fa.rtv_step_2_affirmation,
  fa.rtv_step_2_quizcomplete,
  fa.rtv_step_3_affirmation,
  fa.rtv_step_3_quizcomplete,
  fa.rtv_step_4_affirmation,
  fa.rtv_step_4_quizcomplete,
  fa.rtv_step_3_or_4_affirmation,
  fa.rtv_step_3_or_4_quizcomplete,
  fa.clicked_get_started_affirmation,
  fa.clicked_get_started_quizcomplete,
  fa.registered,
  fa.registered_quizcomplete,
  fa.clicked_share_fb,
  fa.registered_affirmation,
  fa.submitted_quiz,
  fa.clicked_submit_photo,
  --additional flags from a combination and sequence of events
  CASE
    WHEN registered_affirmation = 1
    AND max_submit_quiz_ts > max_click_registration_ts THEN 1
    ELSE 0
  END AS register_affirmation_THEN_quiz,
  CASE
    WHEN submitted_quiz = 1
    AND registered_affirmation = 1
    AND max_submit_quiz_ts < max_click_registration_ts THEN 1
    ELSE 0
  END AS submit_quiz_register_affirmation,
  CASE
    WHEN submitted_quiz = 1
    AND registered_affirmation = 1
    AND max_submit_quiz_ts > latest_register_ts
    AND max_fb_share_ts > max_submit_quiz_ts THEN 1
    ELSE 0
  END AS share_quiz_post_register_affirm,
  CASE
    WHEN submitted_quiz = 1
    AND registered_affirmation = 1
    AND max_submit_quiz_ts > latest_register_ts
    AND max_submit_photo_ts > max_submit_quiz_ts THEN 1
    ELSE 0
  END AS submit_photo_post_register_affirm,
  CASE
    WHEN submitted_quiz = 1
    AND registered_quizcomplete = 1
    AND max_submit_quiz_ts > latest_register_ts
    AND max_fb_share_ts > max_submit_quiz_ts THEN 1
    ELSE 0
  END AS share_quiz_post_register_qcomp,
  CASE
    WHEN submitted_quiz = 1
    AND registered_quizcomplete = 1
    AND max_submit_quiz_ts > latest_register_ts
    AND max_submit_photo_ts > max_submit_quiz_ts THEN 1
    ELSE 0
  END AS submit_photo_post_register_qcomp
FROM
  session_base s
  LEFT JOIN funnel_landing fl
  ON (
    s.session_id = fl.session_id
    AND s.device_id = fl.device_id
  )
  LEFT JOIN funnel_auth fa
  ON (
    s.session_id = fa.session_id
    AND s.northstar_id = fa.northstar_id
  )