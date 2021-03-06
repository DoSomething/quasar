SELECT
    agent_id AS agent_id,
    attachments->0->>'contentType' AS attachment_content_type,
    attachments->0->>'url' AS attachment_url,
    broadcast_id AS broadcast_id,
    campaign_id AS campaign_id,
    conversation_id AS conversation_id,
    created_at as created_at,
    direction AS direction,
    _id AS message_id,
    macro AS macro,
    match AS match,
    metadata #>> '{delivery,deliveredAt}' AS carrier_delivered_at,
    metadata #>> '{delivery,failureData,code}' as carrier_failure_code,
    (metadata #> '{delivery}' ->> 'totalSegments')::INT AS total_segments,
    platform_message_id as platform_message_id,
    template AS template,
    text AS text,
    topic AS topic,
    user_id AS user_id
  FROM {{ source('gambit', 'messages') }}
