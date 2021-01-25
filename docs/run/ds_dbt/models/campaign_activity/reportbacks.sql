

  create  table "quasar"."public"."reportbacks__dbt_tmp"
  as (
    WITH first_rb AS (
	SELECT
		min(id) AS post_id
	FROM
		"quasar"."public"."posts" p
	WHERE
		p.is_reportback = 'true'
		AND p.is_accepted = 1
	GROUP BY
		p.northstar_id,
		p.campaign_id,
		p.signup_id,
		p.post_class,
		p.reportback_volume
	UNION
	DISTINCT
	SELECT
		id
	FROM
		"quasar"."public"."posts" p
	WHERE
		p.is_reportback = 'true'
		AND p.is_accepted = 1
		AND TYPE = 'voter-reg'
)
SELECT
	pd."action" AS post_action,
	pd.campaign_id,
	pd.club_id,
	pd.group_id,
	pd.id AS post_id,
	pd.is_civic_action,
	pd.is_scholarship_entry,
	pd.location,
	pd.northstar_id,
	pd."type" AS post_type,
	pd.post_class,
	pd.signup_id,
	pd.source AS post_source,
	pd.source_bucket AS post_source_bucket,
	pd.status AS post_status,
	pd.hours_spent as hours_spent,
	pd.created_at AS post_created_at,
	pd.postal_code,
	CASE
		WHEN (
			pd.post_class ILIKE '%vote%'
			AND pd.status = 'confirmed'
		) THEN 'self-reported registrations'
		WHEN (
			pd.post_class ILIKE 'voter-reg - %'
			AND pd.status <> 'confirmed'
		) THEN 'voter_registrations'
		WHEN pd."type" ILIKE '%photo%'
		AND pd.post_class NOT ILIKE '%vote%' THEN 'photo_rbs'
		WHEN pd."type" ILIKE '%text%' THEN 'text_rbs'
		WHEN pd."type" ILIKE '%social%' THEN 'social'
		WHEN pd."type" ILIKE '%call%' THEN 'phone_calls'
		ELSE NULL
	END AS post_bucket,
	pd.reportback_volume,
	pd.vr_source,
	pd.vr_source_details
FROM
	"quasar"."public"."posts" pd
	JOIN first_rb f ON (pd.id = f.post_id)
  );