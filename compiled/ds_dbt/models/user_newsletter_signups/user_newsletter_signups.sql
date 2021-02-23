WITH 
recent_signups AS (
	SELECT s.northstar_id, s.created_at AS signup_date, 
	CASE WHEN source_bucket='sms' THEN 'sms' ELSE 'web' END AS signup_source
	FROM "quasar_prod_warehouse"."public"."signups" s
	WHERE s.created_at >= date('2019-03-01')
	
),
user_nl_su AS (
	SELECT u.northstar_id,
	       u.last_mam,
	       u.months_since_created,
	       u.period_start,
	       u.period_end, 
		   u.newsletter_topic,
		   u.subscribed,
		   u.unsubscribed, 
			--As per requirements, we don't count subscriptions that occurr while the user signs-up
		   CASE WHEN date_trunc('day',s.signup_date)=date_trunc('day',u.subscribed) THEN NULL
		   		WHEN s.signup_date BETWEEN u.period_start and u.period_end 
		   		THEN s.signup_source 
		   ELSE NULL END AS signup_source,
		   CASE WHEN date_trunc('day',s.signup_date) = date_trunc('day',u.subscribed) THEN NULL
		   		WHEN s.signup_date BETWEEN u.period_start AND u.period_end 
		   		THEN s.signup_date 
		   ELSE NULL END AS signup_date
	FROM "quasar_prod_warehouse"."public"."user_newsletter_cal_status" u
	LEFT JOIN recent_signups s ON (u.northstar_id = s.northstar_id)
	WHERE (s.signup_date BETWEEN u.period_start AND u.period_end OR s.northstar_id IS NULL)

)
SELECT northstar_id, 
       months_since_created,
       last_mam,
       period_start,
       period_end, 
	   newsletter_topic,
	   subscribed,
	   unsubscribed,
	   CASE WHEN subscribed IS NOT NULL AND signup_date IS NULL THEN 'Subscribed' 
	   	 	WHEN subscribed IS NOT NULL AND unsubscribed IS NULL AND signup_date > SUBSCRIBED THEN 'Subscribed'
	   	 	WHEN subscribed IS NOT NULL AND signup_date BETWEEN subscribed AND coalesce(unsubscribed,period_end) THEN 'Subscribed'
	   	 	WHEN subscribed IS NULL AND unsubscribed IS NOT NULL AND signup_date IS NULL THEN 'Subscribed'
	   	 	WHEN subscribed IS NULL AND unsubscribed IS NOT NULL AND signup_date < unsubscribed THEN 'Subscribed'
	   ELSE 'Not Subscribed' END AS nl_status,
	 signup_source, signup_date
FROM user_nl_su