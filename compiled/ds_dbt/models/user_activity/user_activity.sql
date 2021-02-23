WITH
rb_summary AS (
    SELECT
	r_with_lag.northstar_id,
	sum(r_with_lag.reportback_volume) AS total_quantity,
	count(DISTINCT r_with_lag.campaign_id) AS num_rbs,
	max(r_with_lag.post_created_at) AS most_recent_rb,
	min(r_with_lag.post_created_at) AS first_rb,
	avg(r_with_lag.time_betw_rbs) AS avg_time_betw_rbs
    FROM (
	SELECT
	    *,
	    post_created_at - lag(post_created_at) OVER (
		PARTITION BY northstar_id ORDER BY post_created_at) AS time_betw_rbs
	FROM "quasar_prod_warehouse"."public"."reportbacks"
    ) r_with_lag
    GROUP BY r_with_lag.northstar_id
),
gambit_unsub AS (
    SELECT
	f.user_id,
	CASE WHEN f.last_macro = 'subscriptionStatusStop' OR f.last_topic = 'unsubscribed'
	THEN f.last_ts ELSE NULL END AS unsub_ts
    FROM (
	SELECT DISTINCT
	    user_id,
	    LAST_VALUE(macro) OVER (PARTITION BY user_id ORDER BY created_at
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_macro,
	    LAST_VALUE(topic) OVER (PARTITION BY user_id ORDER BY created_at
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_topic,
	    LAST_VALUE(created_at) OVER (PARTITION BY user_id ORDER BY created_at
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_ts
	FROM "quasar_prod_warehouse"."public"."gambit_messages_inbound"
    ) f
),
-- If the member's sms_status is 'unknown', 'undeliverable' or 'GDPR'.
-- The timestamp of when it was last updated in the user's app database is used
-- as the timestamp this user was set as undeliverable.
-- More details on the decision why we are using this logic as a "good enough" proxy
-- to the real undeliverability timestamp can be found in https://www.pivotaltracker.com/story/show/171448501
sms_undeliverable AS (
    SELECT DISTINCT
	    northstar_id,
	    FIRST_VALUE(updated_at) OVER (PARTITION BY northstar_id ORDER BY updated_at
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS undeliverable_ts
    FROM "quasar_prod_warehouse"."public"."northstar_users_deduped"
    WHERE sms_status IN ('unknown', 'undeliverable', 'GDPR')
),
email_unsub AS (
    SELECT
	f.customer_id,
	CASE WHEN f.last_status = 'customer_unsubscribed' THEN f.last_ts ELSE NULL
	    END AS email_unsubscribed_at
    FROM (
	SELECT DISTINCT
	    customer_id,
	    LAST_VALUE("timestamp") OVER (
		PARTITION BY customer_id ORDER BY "timestamp", event_type
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_ts,
	    LAST_VALUE(event_type) OVER (
		PARTITION BY customer_id ORDER BY "timestamp", event_type
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_status
	    FROM "quasar_prod_warehouse"."public"."cio_customer_event"
    ) f
),
time_to_actions AS (
    SELECT
	f.northstar_id,
	avg(date_part('day', f.time_to_next_action)) AS avg_days_next_action_after_rb,
	min(date_part('day', f.time_to_next_action_last_rb)) AS days_to_next_action_after_last_rb
    FROM (
	SELECT
	    r.northstar_id,
	    mel.next_action_ts - r.post_created_at AS time_to_next_action,
	    LAST_VALUE(mel.next_action_ts - r.post_created_at) OVER (
		PARTITION BY r.northstar_id ORDER BY r.post_created_at
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	    ) AS time_to_next_action_last_rb
	FROM "quasar_prod_warehouse"."public"."reportbacks" r
	LEFT JOIN LATERAL (
	    SELECT "timestamp" AS next_action_ts, action_type AS next_action_type
	    FROM "quasar_prod_warehouse"."public"."member_event_log"
	    WHERE northstar_id = r.northstar_id AND "timestamp" > r.post_created_at
	    ORDER BY "timestamp" ASC
	    LIMIT 1
	) mel
	ON TRUE
    ) f
    GROUP BY f.northstar_id
)
SELECT
u.northstar_id,
u.created_at,
u.sms_status,
u.cio_status AS email_status,
s.num_signups,
s.most_recent_signup,
r.num_rbs,
r.total_quantity,
r.most_recent_rb,
r.first_rb,
r.avg_time_betw_rbs,
time_to_actions.avg_days_next_action_after_rb,
time_to_actions.days_to_next_action_after_last_rb,
mel.most_recent_action AS most_recent_mam_action,
email_opens.most_recent_email_open,
greatest(
    mel.most_recent_action,
    email_opens.most_recent_email_open
) AS most_recent_all_actions,
CASE WHEN time_to_actions.days_to_next_action_after_last_rb IS NULL
    AND r.num_rbs > 0 THEN TRUE END AS last_action_is_rb,
DATE_PART(
    'day', now() - greatest(mel.most_recent_action, email_opens.most_recent_email_open)
) as days_since_last_action,
(r.first_rb - u.created_at) AS time_to_first_rb,
gambit_unsub.unsub_ts AS sms_unsubscribed_at,
sms_undeliverable.undeliverable_ts AS sms_undeliverable_at,
email_unsub.email_unsubscribed_at,
CASE WHEN u.subscribed_member IS FALSE
    THEN greatest(
	gambit_unsub.unsub_ts,
	email_unsub.email_unsubscribed_at) ELSE NULL
    END AS user_unsubscribed_at,
CASE WHEN u."source" = 'importer-client' AND p.first_post = 'voter-reg'
    THEN 1 ELSE 0 END AS voter_reg_acquisition
FROM "quasar_prod_warehouse"."public"."users" u
LEFT JOIN (
SELECT
    northstar_id,
    count(DISTINCT campaign_id) AS num_signups,
    max(created_at) AS most_recent_signup
FROM "quasar_prod_warehouse"."public"."signups"
GROUP BY northstar_id
) s
ON u.northstar_id = s.northstar_id
LEFT JOIN rb_summary r
ON u.northstar_id = r.northstar_id
LEFT JOIN (
    SELECT northstar_id, max("timestamp") AS most_recent_action
    FROM "quasar_prod_warehouse"."public"."member_event_log"
    GROUP BY northstar_id
) mel
ON u.northstar_id = mel.northstar_id
LEFT JOIN (
    SELECT customer_id, max("timestamp") AS most_recent_email_open
    FROM "quasar_prod_warehouse"."public"."cio_email_events"
    WHERE event_type = 'email_opened'
    GROUP BY customer_id
) email_opens
ON u.northstar_id = email_opens.customer_id
LEFT JOIN gambit_unsub
ON u.northstar_id = gambit_unsub.user_id
LEFT JOIN sms_undeliverable
ON u.northstar_id = sms_undeliverable.northstar_id
LEFT JOIN email_unsub
ON u.northstar_id = email_unsub.customer_id
LEFT JOIN time_to_actions
ON u.northstar_id = time_to_actions.northstar_id
LEFT JOIN (
    SELECT DISTINCT
	northstar_id,
	FIRST_VALUE("type") OVER (
	    PARTITION BY northstar_id ORDER BY created_at) AS first_post
    FROM "quasar_prod_warehouse"."public"."posts"
) p
ON u.northstar_id = p.northstar_id