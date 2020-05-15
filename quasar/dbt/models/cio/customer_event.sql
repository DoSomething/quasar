SELECT
    COALESCE(
        event #>>'{data, email_id}',
        event #>>'{data, variables, email_id}'
    ) AS email_id,
    event #>>'{data, customer_id}' as customer_id,
    event #>>'{data, email_address}' as email_address,
    event #>>'{data, template_id}' as template_id,
    event ->> 'event_id' AS event_id,
    TO_TIMESTAMP(CAST(event ->> 'timestamp' AS INTEGER)) AS "timestamp",
    event ->> 'event_type' AS event_type,
    event #>>'{data, variables, campaign, id}' as cio_campaign_id,
    event #>>'{data, variables, campaign, name}' as cio_campaign_name,
    event #>>'{data, variables, campaign, type}' as cio_campaign_type
FROM
    { { source('cio', 'event_log') } } cel
WHERE
    event ->> 'event_type' IN ('customer_subscribed', 'customer_unsubscribed')
