SELECT id AS post_id, 
	details::jsonb->>'hostname' AS hostname,
	details::jsonb->>'referral-code' AS referral_code,
	details::jsonb->>'partner-comms-opt-in' AS partner_comms_opt_in,
	(details::jsonb->>'created-at')::timestamp AS created_at,
	(details::jsonb->>'updated-at')::timestamp AS updated_at,
	source_details,
	details::jsonb->>'voter-registration-status' AS voter_registration_status,
	details::jsonb->>'voter-registration-source' AS voter_registration_source,
	details::jsonb->>'voter-registration-method' AS voter_registration_method,
	details::jsonb->>'voting-method-preference' AS voter_registration_preference,
	details::jsonb->>'email subscribed' AS email_subscribed,
	details::jsonb->>'sms subscribed' AS sms_subscribed
FROM "quasar_prod_warehouse"."ft_dosomething_rogue"."posts"
WHERE source = 'turbovote'