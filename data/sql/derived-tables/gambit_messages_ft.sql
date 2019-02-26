DROP MATERIALIZED VIEW IF EXISTS ft_gambit_conversations_api.messages_flattened_ft CASCADE;
CREATE MATERIALIZED VIEW ft_gambit_conversations_api.messages_flattened_ft AS
(SELECT 
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
    metadata #>> '{delivery,queuedAt}' AS delivered_at,
    (metadata #> '{delivery}' ->> 'totalSegments')::INT AS total_segments,
    platform_message_id as platform_message_id,
    template AS template,
    text AS text,
    topic AS topic,
    user_id AS user_id
 FROM ft_gambit_conversations_api.messages
);

CREATE INDEX platformmsgi_ft ON ft_gambit_conversations_api.messages_flattened_ft(platform_message_id);
CREATE INDEX usermidi_ft ON ft_gambit_conversations_api.messages_flattened_ft(user_id);

GRANT SELECT ON ft_gambit_conversations_api.messages_flattened_ft TO looker;
GRANT SELECT ON ft_gambit_conversations_api.messages_flattened_ft to dsanalyst;

DROP MATERIALIZED VIEW IF EXISTS public.gambit_messages_inbound_ft CASCADE;
CREATE MATERIALIZED VIEW public.gambit_messages_inbound_ft AS
(SELECT
	*
FROM
	ft_gambit_conversations_api.messages_flattened_ft f
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
	ft_gambit_conversations_api.messages_flattened_ft g
LEFT JOIN
	ft_gambit_conversations_api.conversations c
	ON g.conversation_id = c._id
LEFT JOIN
	public.users u
	ON substring(c.platform_user_id, 3, 10) = u.mobile
	AND u.mobile IS NOT NULL
	AND u.mobile <> ''
WHERE
	g.direction = 'inbound'
	AND g.user_id IS NULL));

CREATE INDEX inbound_messages_ft_i ON public.gambit_messages_inbound_ft (message_id, created_at, user_id, conversation_id);
GRANT SELECT ON public.gambit_messages_inbound_ft to looker;
GRANT SELECT ON public.gambit_messages_inbound_ft to dsanalyst;

DROP MATERIALIZED VIEW IF EXISTS public.gambit_messages_outbound_ft CASCADE;
CREATE MATERIALIZED VIEW public.gambit_messages_outbound_ft AS
(SELECT
	f.campaign_id,
	f.conversation_id,
	f.broadcast_id,
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
	ft_gambit_conversations_api.messages_flattened_ft f
WHERE
	f.direction <> 'inbound'
	AND f.user_id IS NOT NULL
UNION ALL
(SELECT
	g.campaign_id,
	g.conversation_id,
	g.broadcast_id,
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
	ft_gambit_conversations_api.messages_flattened_ft g
LEFT JOIN
	ft_gambit_conversations_api.conversations c
	ON g.conversation_id = c._id
LEFT JOIN
	public.users u
	ON substring(c.platform_user_id, 3, 10) = u.mobile
	AND u.mobile IS NOT NULL
	AND u.mobile <> ''
WHERE
	g.direction <> 'inbound'
	AND g.user_id IS NULL));

CREATE INDEX outbound_messages_ft_i ON public.gambit_messages_outbound_ft (message_id, created_at, user_id, conversation_id);
GRANT SELECT ON public.gambit_messages_outbound_ft to looker;
GRANT SELECT ON public.gambit_messages_outbound_ft to dsanalyst;

