SELECT DISTINCT
	_id as northstar_id,
	(audit #>> '{email_subscription_topics,updated_at,date}')::timestamp AS newsletter_updated_at,
	json_array_elements(u.email_subscription_topics::json)::TEXT AS newsletter_topic
FROM "quasar_prod_warehouse"."northstar_ft_userapi"."northstar_users_snapshot" u
WHERE audit #>> '{email_subscription_topics,updated_at,date}' IS NOT NULL