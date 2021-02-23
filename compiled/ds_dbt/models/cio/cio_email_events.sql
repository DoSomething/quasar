SELECT
    event #>>'{data, customer_id}' as customer_id,
    event #>>'{data, email_address}' as email_address,
	coalesce(
	    event #>>'{data, email_id}',
	    event #>>'{data, variables, email_id}'
	) AS email_id,
    event ->> 'event_id' AS event_id,
    event ->> 'event_type' AS event_type,
    event #>>'{data, href}' as href,
    event #>>'{data, link_id}' as link_id,
    event #>>'{data, subject}' as subject,
    CAST(
        event #>>'{data, template_id}' AS INTEGER
    ) AS template_id,
    TO_TIMESTAMP(CAST(event ->> 'timestamp' AS INTEGER)) AS "timestamp",
	event #>>'{data, variables, campaign, id}' as cio_campaign_id,
	event #>>'{data, variables, campaign, name}' as cio_campaign_name,
	event #>>'{data, variables, campaign, type}' as cio_campaign_type,
    event #>>'{data, message_id}' as cio_message_id,
    event #>>'{data, message_name}' as cio_message_name
FROM
    "quasar_prod_warehouse"."cio"."event_log" cel
WHERE event ->> 'event_type' IN ('email_bounced', 'email_converted', 'email_opened', 'email_unsubscribed', 'email_clicked', 'email_sent')
UNION
SELECT
    customer_id,
    email_address,
    email_id,
    event_id,
    event_type,
    href,
    link_id,
    "subject",
    template_id,
    "timestamp",
    NULL AS cio_campaign_id,
    NULL AS cio_campaign_name,
    NULL AS cio_campaign_type,
    NULL AS cio_message_id,
    NULL AS cio_message_name
FROM "quasar_prod_warehouse"."historical_analytics"."cio_email_events"
WHERE
    -- Date we re-started saving raw C.io events to the event_log table
    "timestamp" < '2020-04-01'