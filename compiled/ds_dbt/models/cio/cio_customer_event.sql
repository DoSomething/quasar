SELECT
    COALESCE(
        event #>>'{data, email_id}',
        event #>>'{data, variables, email_id}'
    ) AS email_id,
    event #>>'{data, customer_id}' AS customer_id,
    event #>>'{data, email_address}' AS email_address,
    CAST(
        event #>>'{data, template_id}' AS INTEGER
    ) AS template_id,
    event ->> 'event_id' AS event_id,
    TO_TIMESTAMP(
        CAST(event ->> 'timestamp' AS INTEGER)
    ) AS "timestamp",
    event ->> 'event_type' AS event_type,
    event #>>'{data, variables, campaign, id}' AS cio_campaign_id,
    event #>>'{data, variables, campaign, name}' AS cio_campaign_name,
    event #>>'{data, variables, campaign, type}' AS cio_campaign_type,
    event #>>'{data, message_id}' as cio_message_id,
    event #>>'{data, message_name}' as cio_message_name
FROM
    "quasar_prod_warehouse"."cio"."event_log" cel
WHERE
    event ->> 'event_type' IN ('customer_subscribed', 'customer_unsubscribed')
UNION
SELECT
    email_id,
    customer_id,
    email_address,
    template_id,
    event_id,
    "timestamp",
    event_type,
    NULL AS cio_campaign_id,
    NULL AS cio_campaign_name,
    NULL AS cio_campaign_type,
    NULL AS cio_message_id,
    NULL AS cio_message_name
FROM
    "quasar_prod_warehouse"."historical_analytics"."cio_customer_event" cceo
WHERE
    -- Date we re-started saving raw C.io events to the event_log table
    "timestamp" < '2020-04-01'