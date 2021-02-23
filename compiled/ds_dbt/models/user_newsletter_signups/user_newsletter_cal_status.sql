WITH user_newsletter_cal_status_temp AS (
SELECT u.northstar_id, 
       u.created_at_month, 
       u.last_mam, 
       u.months_since_created, 
       u.period_start, 
       u.period_end,
	   u.newsletter_topic,
	CASE WHEN nl.topic_subscribed_at IS NULL 
		   OR nl.topic_subscribed_at > u.period_end
		   OR nl.topic_unsubscribed_at < u.period_start
		   THEN NULL
		ELSE nl.topic_subscribed_at END AS subscribed, 
	CASE WHEN nl.topic_unsubscribed_at IS NULL 
		   OR nl.topic_unsubscribed_at > u.period_end
		   OR nl.topic_unsubscribed_at < u.period_start
		   OR nl.topic_subscribed_at > u.period_end 
		   THEN NULL 
		ELSE nl.topic_unsubscribed_at END AS unsubscribed
FROM "quasar_prod_warehouse"."public"."user_newsletter_cal_multi" u
LEFT JOIN "quasar_prod_warehouse"."public"."user_newsletter_subscriptions" nl ON (u.northstar_id = nl.northstar_id AND u.newsletter_topic = nl.newsletter_topic))
SELECT *
FROM user_newsletter_cal_status_temp
-- The UNION ALL below originally started as an INSERT * FROM above query. Using UNION ALL and user_newsletter_cal_status_temp CTE to generate all records.
UNION ALL
SELECT n1.northstar_id,
	   n1.created_at_month, 
	   n1.last_mam, 
	   n1.months_since_created, 
	   n1.period_start, 
	   n1.period_end,
	   --n1.subscribed, n2.subscribed, n1.unsubscribed, n2.unsubscribed, 
	   concat(n1.newsletter_topic, '-', n2.newsletter_topic) AS newsletter_topic,
	   CASE WHEN (n1.subscribed IS NOT NULL AND n2.subscribed IS NOT NULL) THEN greatest(n1.subscribed,n2.subscribed) END AS subscribed, 
	   CASE WHEN (n1.subscribed IS NOT NULL AND n2.subscribed IS NOT NULL) THEN least(n1.unsubscribed,n2.unsubscribed) END AS unsubscribed
FROM user_newsletter_cal_status_temp n1
JOIN user_newsletter_cal_status_temp n2 ON (n1.northstar_id = n2.northstar_id AND n1.months_since_created = n2.months_since_created)
WHERE (n1.newsletter_topic = '"community"' AND N2.newsletter_topic = '"lifestyle"')