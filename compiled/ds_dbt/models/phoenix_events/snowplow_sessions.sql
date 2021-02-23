-- Each session can be thought of a 0 - 3600 seconds (60 min) block of time
-- It holds event metadata for the duration of the session
WITH sessions AS (
SELECT
    session_id,
    min(device_id) AS device_id,
    min(event_datetime) AS landing_datetime,
    max(event_datetime) AS ending_datetime,
    date_part(
	'seconds', max(event_datetime) - min(event_datetime)
    ) AS session_duration_seconds,
    count(DISTINCT CASE WHEN event_name = 'view' THEN "path" END) AS num_pages_viewed
FROM "quasar_prod_warehouse"."public"."snowplow_raw_events"

-- this filter will only be applied on an incremental run
WHERE event_datetime >= (select max(ss.landing_datetime) from "quasar_prod_warehouse"."public"."snowplow_sessions" ss)

GROUP BY session_id
),
-- Captures the first and last page viewed metadata per session
-- IMPORTANT: The event id is the first event in the session.
entry_exit_pages AS (
SELECT
    session_id,
    first_value("path") OVER (PARTITION BY session_id ORDER BY event_datetime
	ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS landing_page,
    first_value(event_id) OVER (PARTITION BY session_id ORDER BY event_datetime
	ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_event_id,
    last_value("path") OVER (PARTITION BY session_id ORDER BY event_datetime
	ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS exit_page
FROM "quasar_prod_warehouse"."public"."snowplow_raw_events"

-- this filter will only be applied on an incremental run
WHERE event_datetime >= (select max(ss.landing_datetime) from "quasar_prod_warehouse"."public"."snowplow_sessions" ss)

),
-- Captures referrer metadata per session
session_referrer AS (
SELECT
    session_id,
    first_value(referrer_host) OVER (PARTITION BY session_id ORDER BY event_datetime 
	ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS session_referrer_host,
    first_value(utm_source) OVER (PARTITION BY session_id ORDER BY event_datetime
	ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS session_utm_source,
    first_value(utm_campaign) OVER (PARTITION BY session_id ORDER BY event_datetime
	ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS session_utm_campaign 
FROM "quasar_prod_warehouse"."public"."snowplow_raw_events"

-- this filter will only be applied on an incremental run
WHERE event_datetime >= (select max(ss.landing_datetime) from "quasar_prod_warehouse"."public"."snowplow_sessions" ss)

),
-- Captures last recorded session metadata for this device
time_between_sessions AS (
SELECT
    device_id,
    session_id,
    LAG(ending_datetime) OVER (PARTITION BY device_id ORDER BY landing_datetime
	ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS prev_session_endtime
FROM sessions

-- this filter will only be applied on an incremental run
WHERE landing_datetime >= (select max(ss.landing_datetime) from "quasar_prod_warehouse"."public"."snowplow_sessions" ss)

)
SELECT DISTINCT
s.session_id,
p.first_event_id,
s.device_id,
s.landing_datetime,
s.ending_datetime,
r.session_referrer_host,
r.session_utm_source,
r.session_utm_campaign,
s.session_duration_seconds,
s.num_pages_viewed,
p.landing_page,
p.exit_page,
-- default to 0 days if there was no previous session
COALESCE(date_part('day', s.landing_datetime - t.prev_session_endtime),0) AS days_since_last_session
FROM sessions s
LEFT JOIN entry_exit_pages p
ON p.session_id = s.session_id
LEFT JOIN session_referrer r
ON r.session_id = s.session_id
LEFT JOIN time_between_sessions t
ON t.session_id = s.session_id


-- this filter will only be applied on an incremental run
WHERE landing_datetime >= (select max(ss.landing_datetime) from "quasar_prod_warehouse"."public"."snowplow_sessions" ss)
