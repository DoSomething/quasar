SELECT
	a.name AS "action",
	pd.action_id,
	pd.campaign_id,
	pd.club_id,
	CASE
		WHEN pd."type" = 'phone-call' AND pd.details <> ''
		THEN (pd.details::json ->> 'call_timestamp')::timestamptz
		ELSE COALESCE(rtv.created_at, tv.created_at, pd.created_at)
	END AS created_at,
	pd.group_id,
	pd.id AS id,
	CASE WHEN pd.status IN ('accepted', 'pending')
		AND a."name" NOT ILIKE '%vote%'
		THEN 1
		WHEN pd.status IN ('accepted', 'confirmed', 'register-OVR', 'register-form')
		AND a."name" ILIKE '%vote%'
		THEN 1
		ELSE NULL
	END AS is_accepted,
	a.anonymous AS is_anonymous,
	a.civic_action AS is_civic_action,
	a.online AS is_online,
	a.quiz AS is_quiz,
	a.reportback AS is_reportback,
	a.scholarship_entry AS is_scholarship_entry,
	a.time_commitment AS time_commitment,
	a.volunteer_credit AS is_volunteer_credit,
	pd.location,
	pd.northstar_id AS northstar_id,
	a.noun,
	CASE
	    WHEN pd.details <> ''
		THEN (pd.details::json ->> 'number_of_participants')::INT
	    ELSE NULL
	END AS num_participants,
	pd.postal_code,
	CASE
		WHEN pd.id IS NULL
		THEN NULL
		ELSE CONCAT(pd."type", ' - ', a."name")
	END AS post_class,
	pd.quantity AS quantity,
	pd.referrer_user_id,
	CASE
		WHEN pd.id IS NULL THEN NULL
		WHEN a."name" = 'voter-reg OTG'
		THEN pd.quantity
		ELSE 1
	END AS reportback_volume,
	pd.school_id,
	CASE
		WHEN pd."source" IS NULL THEN NULL
		WHEN pd."source" ilike '%sms%' THEN 'sms'
		ELSE 'web'
	END AS source_bucket,
	CASE
		WHEN s."source" = 'importer-client'
		AND pd."type" = 'share-social'
		AND pd.created_at < s.created_at
		THEN -1
		ELSE pd.signup_id
	END AS signup_id,
	pd."source" AS "source",
	pd.status AS "status",
	pd.text,
	pd."type" AS "type",
	pd.hours_spent,
	pd.url AS url,
	a.verb,
	CASE
		WHEN rtv.tracking_source='ads'
		THEN 'ads'
		ELSE split_part(substring(rtv.tracking_source from 'source\:(.+)'), ',', 1)
	END AS vr_source,
	split_part(substring(rtv.tracking_source from 'source_details\:(.+)'), ',', 1) AS vr_source_details
FROM {{ source('rogue', 'posts') }} pd
INNER JOIN {{ ref('signups') }} s
	ON pd.signup_id = s.id
LEFT JOIN {{ ref('turbovote') }} tv
	ON tv.post_id::bigint = pd.id::bigint
LEFT JOIN
	(SELECT
		DISTINCT r.*,
		CASE
			WHEN r.started_registration < '2017-01-01'
			THEN r.started_registration + interval '4 year'
			ELSE r.started_registration END AS created_at
		FROM {{ ref('rock_the_vote') }} r
	) rtv
	ON rtv.post_id::bigint = pd.id::bigint
LEFT JOIN {{ source('rogue', 'actions') }} a
	ON pd.action_id = a.id
WHERE pd.deleted_at IS NULL
AND pd."text" IS DISTINCT FROM 'test runscope upload'
AND a."name" IS NOT NULL
