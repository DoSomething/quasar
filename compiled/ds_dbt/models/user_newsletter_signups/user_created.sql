WITH
user_mam AS (
	SELECT northstar_id, min(date(timestamp)) AS first_mam, max(date(timestamp)) AS last_mam
	FROM "quasar_prod_warehouse"."public"."member_event_log"
	WHERE action_type <> 'account_creation'
	AND timestamp >= '2008-01-01'
	GROUP BY 1
)
SELECT u.northstar_id, u.email, u.created_at, 
	CASE WHEN date(u.created_at) > date(a.first_mam) 
		 THEN date_trunc('month', date(a.first_mam)) 
		 ELSE date_trunc('month', date(u.created_at)) 
	END AS created_at_month,
	first_mam, last_mam
   FROM "quasar_prod_warehouse"."public"."users" u
   JOIN user_mam a ON u.northstar_id = a.northstar_id
   WHERE (u.email IS NULL OR u.email NOT LIKE '%@dosomething.org' OR email NOT LIKE '%invalid%')