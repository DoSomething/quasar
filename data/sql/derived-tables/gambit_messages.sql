DROP MATERIALIZED VIEW IF EXISTS gambit.messages_flattened CASCADE;
CREATE MATERIALIZED VIEW gambit.messages_flattened AS
(SELECT
    records ->> 'agentId' AS agent_id,
    records #>> '{attachments,url}' AS attachment_url,
    records ->> '{attachments,contentType}'as attachment_content_type,
    records ->> 'broadcastId' AS broadcast_id,
    records ->> 'campaignId' AS campaign_id,
    records #>> '{conversationId,$oid}' AS conversation_id,
    to_timestamp((((records #>> '{createdAt,$date}')::BIGINT) / 1000)::DOUBLE PRECISION) AS created_at,
    records ->> 'direction' AS direction,
    records #>> '{_id,$oid}' AS message_id,
    records ->> 'macro' AS macro,
    records ->> 'match' AS match,
    to_timestamp((records #> '{metadata,delivery}' #>> '{deliveredAt,$date}')::BIGINT / 1000::DOUBLE PRECISION) AS delivered_at,
    (records #> '{metadata,delivery}' ->> 'totalSegments')::INT AS total_segments,
    records ->> 'platformMessageId' AS platform_message_id,
    records ->> 'template' AS template,
    records ->> 'text' AS text,
    records ->> 'topic' AS topic,
    records ->> 'userId' AS user_id
FROM gambit.messages_json);

CREATE INDEX platformmsgi ON gambit.messages_flattened(platform_message_id);
CREATE INDEX usermidi ON gambit.messages_flattened(user_id);

GRANT SELECT ON gambit.messages_flattened TO looker;
GRANT SELECT ON gambit.messages_flattened to dsanalyst;

DROP MATERIALIZED VIEW IF EXISTS public.gambit_messages_inbound CASCADE;
CREATE MATERIALIZED VIEW public.gambit_messages_inbound AS
(SELECT
	*
FROM
	gambit.messages_flattened f
WHERE
	f.direction = 'inbound'
	AND f.user_id IS NOT NULL
UNION ALL
(SELECT
	g.agent_id,
	g.attachment_url,
	g.attachment_content_type,
	g.broadcast_id,
	g.campaign_id,
	g.conversation_id,
	g.created_at,
	g.direction,
	g.message_id,
	g.macro,
	g."match",
	g.delivered_at,
	g.total_segments,
	g.platform_message_id,
	g.template,
	g.text,
	g.topic,
	u.northstar_id AS user_id
FROM
	gambit.messages_flattened g
LEFT JOIN
	gambit.conversations_flattened c
	ON g.conversation_id = c.conversation_id
LEFT JOIN
	public.users u
	ON substring(c.platform_user_id, 3, 10) = u.mobile
	AND u.mobile IS NOT NULL
	AND u.mobile <> ''
WHERE
	g.direction = 'inbound'
	AND g.user_id IS NULL));

CREATE INDEX inbound_messages_i ON public.gambit_messages_inbound (message_id, created_at, user_id, conversation_id);
GRANT SELECT ON public.gambit_messages_inbound to looker;
GRANT SELECT ON public.gambit_messages_inbound to dsanalyst;

DROP MATERIALIZED VIEW IF EXISTS public.gambit_messages_outbound CASCADE;
CREATE MATERIALIZED VIEW public.gambit_messages_outbound AS
(SELECT
	f.campaign_id,
	f.conversation_id,
	f.created_at,
	f.direction,
	f.message_id,
	f.macro,
	f."match",
	f.platform_message_id,
	f.template,
	f.text,
	f.topic,
	f.user_id
FROM
	gambit.messages_flattened f
WHERE
	f.direction <> 'inbound'
	AND f.user_id IS NOT NULL
UNION ALL
(SELECT
	g.campaign_id,
	g.conversation_id,
	g.created_at,
	g.direction,
	g.message_id,
	g.macro,
	g."match",
	g.platform_message_id,
	g.template,
	g.text,
	g.topic,
	u.northstar_id AS user_id
FROM
	gambit.messages_flattened g
LEFT JOIN
	gambit.conversations_flattened c
	ON g.conversation_id = c.conversation_id
LEFT JOIN
	public.users u
	ON substring(c.platform_user_id, 3, 10) = u.mobile
	AND u.mobile IS NOT NULL
	AND u.mobile <> ''
WHERE
	g.direction <> 'inbound'
	AND g.user_id IS NULL));

CREATE INDEX outbound_messages_i ON public.gambit_messages_outbound (message_id, created_at, user_id, conversation_id);
GRANT SELECT ON public.gambit_messages_outbound to looker;
GRANT SELECT ON public.gambit_messages_outbound to dsanalyst;
