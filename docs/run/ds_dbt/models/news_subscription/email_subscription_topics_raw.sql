

  create  table "quasar"."public"."email_subscription_topics_raw__dbt_tmp"
  as (
    SELECT DISTINCT
	_id as northstar_id,
	(audit #>> '{email_subscription_topics,updated_at,date}')::timestamp AS newsletter_updated_at,
	json_array_elements(u.email_subscription_topics)::TEXT AS newsletter_topic
FROM "quasar"."ft_northstar_ds_northstar_qa"."northstar_users_snapshot" u
WHERE audit #>> '{email_subscription_topics,updated_at,date}' IS NOT NULL
  );