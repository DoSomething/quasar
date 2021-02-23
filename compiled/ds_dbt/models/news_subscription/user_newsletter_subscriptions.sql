SELECT DISTINCT
	f.northstar_id,
	f.newsletter_topic,
	f.topic_subscribed_at::timestamptz,
	CASE WHEN topic_unsubscribed_at IS NOT NULL
	    THEN topic_unsubscribed_at
	    WHEN newsletters_unsubscribed_at IS NOT NULL
	    THEN newsletters_unsubscribed_at
	    WHEN f.topic_updated_at = f.user_updated_at
	    THEN NULL
	    ELSE f.user_updated_at END AS topic_unsubscribed_at
FROM (
	SELECT DISTINCT
		s.northstar_id AS northstar_id,
		s.newsletter_topic,
		first_value(s.newsletter_updated_at) OVER (PARTITION BY s.northstar_id, s.newsletter_topic ORDER BY s.newsletter_updated_at
			) AS topic_subscribed_at,
		last_value(s.newsletter_updated_at) OVER (PARTITION BY s.northstar_id, s.newsletter_topic ORDER BY s.newsletter_updated_at
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS topic_updated_at,	
		last_value(s.newsletter_updated_at) OVER (PARTITION BY s.northstar_id ORDER BY s.newsletter_updated_at
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS user_updated_at,
		u.topic_unsubscribed_at,
		ua.newsletters_unsubscribed_at
	FROM "quasar_prod_warehouse"."public"."email_subscription_topics_raw" s
	LEFT JOIN (
		SELECT
			_id AS id,
			to_timestamp(audit #>> '{email_subscription_topics,updated_at,date}', 'YYYY-MM-DD HH24:MI:SS') AS topic_unsubscribed_at,
			NULL AS newsletter_topic
		FROM "quasar_prod_warehouse"."northstar_ft_userapi"."northstar_users_snapshot"
		WHERE email_subscription_topics IS NULL AND audit #>> '{email_subscription_topics,updated_at,date}' IS NOT NULL
	) u ON u.id = s.northstar_id
    LEFT JOIN (
		SELECT
			northstar_id,
			email_unsubscribed_at AS newsletters_unsubscribed_at,
			NULL AS newsletter_topic
		FROM "quasar_prod_warehouse"."public"."user_activity"
	) ua ON ua.northstar_id = s.northstar_id
) f