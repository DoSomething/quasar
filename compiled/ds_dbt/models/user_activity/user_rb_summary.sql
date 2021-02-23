--user_rb_summary aggregates traits of multiple Report-Backs per SignUp into a single row
--so they can be analized as a single fact of reporting back
--user_rb_summary is used in the final table which will be referenced by Looker in view:
--campaign_funnel
--which is used to generate dashboards:
--Campaign Journey Dashboard (https://dsdata.looker.com/dashboards/183)
--Marketing Journey Dashboard (https://dsdata.looker.com/dashboards/184)

--RBs get info
WITH rbs_all AS (
	SELECT
		r.signup_id,
		r.post_id,
		r.post_created_at,
		r.post_type,
		r.post_source_bucket,
		CASE
			WHEN pa.action_type = ''
			OR pa.action_type = ' ' THEN NULL
			ELSE pa.action_type
		END AS action_type,
		CASE
			WHEN pa.online = TRUE THEN 'Online'
			WHEN pa.online = FALSE THEN 'Offline'
		END AS online_offline,
		CASE
			WHEN pa.scholarship_entry = TRUE THEN 'Scholarship'
			WHEN pa.scholarship_entry = FALSE THEN 'Not Scholarship'
		END AS scholarship
	FROM
		"quasar_prod_warehouse"."public"."reportbacks" r
		JOIN "quasar_prod_warehouse"."public"."posts" p ON (r.post_id = p.id)
		JOIN "quasar_prod_warehouse"."public"."post_actions" pa ON (p.action_id = pa.id)
	WHERE
		r.signup_id > 0
	ORDER BY
		r.signup_id
),
--RBs unique post types
rbs_post_types AS (
	SELECT
		DISTINCT signup_id,
		post_type
	FROM
		rbs_all
),
--RBs agg post types
rbs_post_types_agg AS (
	SELECT
		signup_id,
		string_agg(
			post_type,
			' , '
			ORDER BY
				post_type DESC
		) AS post_types
	FROM
		rbs_post_types
	GROUP BY
		signup_id
),
--RBs unique post sources
rbs_post_sources AS (
	SELECT
		DISTINCT signup_id,
		post_source_bucket
	FROM
		rbs_all
),
--RBs agg post types
rbs_post_sources_agg AS (
	SELECT
		signup_id,
		string_agg(
			post_source_bucket,
			' , '
			ORDER BY
				post_source_bucket DESC
		) AS post_sources
	FROM
		rbs_post_sources
	GROUP BY
		signup_id
),
--RBs unique action types
rbs_action_types AS (
	SELECT
		DISTINCT signup_id,
		action_type
	FROM
		rbs_all
	WHERE
		action_type IS NOT NULL
),
--RBs agg action types
rbs_action_types_agg AS (
	SELECT
		signup_id,
		string_agg(
			action_type,
			' , '
			ORDER BY
				action_type DESC
		) AS action_types
	FROM
		rbs_action_types
	GROUP BY
		signup_id
),
--RBs unique online/offline
rbs_online_offline AS (
	SELECT
		DISTINCT signup_id,
		online_offline
	FROM
		rbs_all
	WHERE
		online_offline IS NOT NULL
),
--RBs agg action types
rbs_online_offline_agg AS (
	SELECT
		signup_id,
		string_agg(
			online_offline,
			' , '
			ORDER BY
				online_offline DESC
		) AS online_offline
	FROM
		rbs_online_offline
	GROUP BY
		signup_id
),
--RBs get summarized
rb_summ AS (
	SELECT
		r.signup_id,
		count(r.post_id) AS num_rbs,
		min(r.post_created_at) AS first_rb
	FROM
		rbs_all r
	GROUP BY
		r.signup_id
)
SELECT
	r.signup_id,
	r.num_rbs,
	r.first_rb,
	rs.post_sources,
	rp.post_types,
	ra.action_types,
	ro.online_offline
FROM
	rb_summ r
	LEFT JOIN rbs_post_types_agg rp ON (r.signup_id = rp.signup_id)
	LEFT JOIN rbs_post_sources_agg rs ON (r.signup_id = rs.signup_id)
	LEFT JOIN rbs_action_types_agg ra ON (r.signup_id = ra.signup_id)
	LEFT JOIN rbs_online_offline_agg ro ON (r.signup_id = ro.signup_id)