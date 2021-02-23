SELECT
	cio.customer_id,
	max(CASE WHEN 
			cio.event_type = 'customer_unsubscribed' 
			THEN 'customer_unsubscribed' 
			ELSE 'customer_subscribed' END) AS event_type,
	max(cio."timestamp") AS "timestamp"
FROM "quasar_prod_warehouse"."public"."cio_customer_event" cio
INNER JOIN
	(SELECT
		ctemp.customer_id,
		max(ctemp."timestamp") AS max_update
	FROM "quasar_prod_warehouse"."public"."cio_customer_event" ctemp
	GROUP BY ctemp.customer_id) cio_max 
		ON cio_max.customer_id = cio.customer_id
		AND cio_max.max_update = cio."timestamp"
GROUP BY cio.customer_id