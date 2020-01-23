SELECT
	nus._id AS northstar_id,
	nus.country,
	nus.birthdate,
	nus.drupal_id::VARCHAR,
	nus.email_subscription_status::int::bool,
	nus.created_at,
	nus.addr_zip,
	nus."language",
	nus."source",
	nus.updated_at,
	nus.CAMPAIGNS::jsonb,
	nus.audit::jsonb,
	nus.first_name,
	nus.email,
	nus.last_name,
	nus.addr_state,
	nus.addr_street_2,
	nus.addr_street_1,
	nus."_method" as "method",
	nus.complete,
	nus.addr_city,
	nus."role",
	nus.sms_status,
	nus.last_authenticated_at,
	nus.last_accessed_at,
	nus.mobile,
	nus.cio_backfilled,
	nus.addr_source,
	nus.source_detail,
	nus.last_messaged_at,
	nus.email_subscription_topics::jsonb,
	nus.sms_paused,
	nus.voting_plan_status,
	nus.voting_plan_time_of_day,
	nus.voting_plan_method_of_transport,
	nus.voting_plan_attending_with,
	nus.voter_registration_status,
	nus.facebook_id::varchar,
	nus.totp,
	nus.subscribed,
	nus.birthdate_timestamp,
	nus.deleted_at::jsonb,
	nus.feature_flags::jsonb,
	nus.dbt_scd_id,
	nus.dbt_updated_at,
	nus.dbt_valid_from,
	nus.dbt_valid_to,
	nus.google_id,
	nus.causes::jsonb,
	nus.school_id
FROM northstar_ft_userapi.northstar_users_snapshot nus
UNION
SELECT
	nu.id,
	nu.country,
	nu.birthdate,
	nu.drupal_id,
	nu.email_subscription_status,
	nu.created_at,
	nu.addr_zip,
	nu."language",
	nu."source",
	nu.updated_at,
	NULL AS CAMPAIGNS,
	NULL AS AUDIT,
	nu.first_name,
	nu.email,
	nu.last_name,
	nu.addr_state,
	nu.addr_street2,
	nu.addr_street1,
	NULL AS "method",
	NULL AS complete,
	nu.addr_city,
	nu."role",
	nu.sms_status,
	nu.last_authenticated_at,
	nu.last_accessed_at,
	nu.mobile,
	NULL AS cio_backfilled,
	nu.addr_source, 
	nu.source_detail, 
	nu.last_messaged_at,
	NULL AS email_subscription_topics,
	NULL AS sms_paused,
	NULL AS voting_plan_status,
	NULL AS voting_plan_time_of_day,
	NULL AS voting_plan_method_of_transport,
	NULL AS voting_plan_attending_with,
	NULL AS voter_registration_status,
	nu.facebook_id,
	NULL AS totp,
	NULL AS SUBSCRIBED,
	NULL AS BIRTHDATE_TIMESTAMP,
	NULL AS DELETED_AT,
	nu.feature_flags::jsonb,
	NULL AS dbt_scd_id,
	NULL AS dbt_updated_at,
	NULL AS dbt_valid_from,
	NULL AS dbt_valid_to,
	NULL AS google_id,
	NULL AS causes,
	nu.school_id
FROM northstar.users nu