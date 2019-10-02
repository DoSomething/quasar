SELECT DISTINCT
	_id as northstar_id,
	(audit #>> '{email_subscription_topics,updated_at,date}')::timestamp AS newsletter_updated_at,
	json_array_elements(u.email_subscription_topics)::TEXT AS newsletter_topic
FROM {{ env_var("NORTHSTAR_FT_SCHEMA") }}.northstar_users_snapshot u
WHERE audit #>> '{email_subscription_topics,updated_at,date}' IS NOT null
