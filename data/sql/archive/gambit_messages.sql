DROP MATERIALIZED VIEW IF EXISTS :ft_gambit_messages_flattened CASCADE;
CREATE MATERIALIZED VIEW :ft_gambit_messages_flattened AS
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
		metadata #>> '{delivery,deliveredAt}' AS carrier_delivered_at,
    metadata #>> '{delivery,failureData,code}' as carrier_failure_code,
    (metadata #> '{delivery}' ->> 'totalSegments')::INT AS total_segments,
    platform_message_id as platform_message_id,
    template AS template,
    text AS text,
    topic AS topic,
    user_id AS user_id
  FROM :ft_gambit_messages
);

CREATE INDEX ON :ft_gambit_messages_flattened (user_id);
CREATE INDEX ON :ft_gambit_messages_flattened (platform_message_id);

GRANT SELECT ON :ft_gambit_messages_flattened TO looker;
GRANT SELECT ON :ft_gambit_messages_flattened to dsanalyst;

DROP MATERIALIZED VIEW IF EXISTS public.gambit_messages_inbound CASCADE;
CREATE MATERIALIZED VIEW public.gambit_messages_inbound AS
 (SELECT
	*
  FROM
	:ft_gambit_messages_flattened f
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
	g.carrier_delivered_at,
	g.carrier_failure_code,
	g.total_segments,
	g.platform_message_id,
	g.template,
	g.text,
	g.topic,
	u.northstar_id AS user_id
  FROM
	:ft_gambit_messages_flattened g
  LEFT JOIN
	:ft_gambit_conversations c
	ON g.conversation_id = c._id
  LEFT JOIN
	public.users u
	ON substring(c.platform_user_id, 3, 10) = u.mobile
	AND u.mobile IS NOT NULL
	AND u.mobile <> ''
  WHERE
	g.direction = 'inbound'
	AND g.user_id IS NULL));

CREATE INDEX ON public.gambit_messages_inbound (message_id, created_at, user_id, conversation_id);
GRANT SELECT ON public.gambit_messages_inbound to looker;
GRANT SELECT ON public.gambit_messages_inbound to dsanalyst;

DROP MATERIALIZED VIEW IF EXISTS public.gambit_messages_outbound CASCADE;
CREATE MATERIALIZED VIEW public.gambit_messages_outbound AS
 (SELECT
	f.campaign_id,
	f.conversation_id,
	f.broadcast_id,
	f.created_at,
	f.direction,
	f.message_id,
	f.macro,
	f."match",
	f.carrier_delivered_at,
	f.carrier_failure_code,
	f.platform_message_id,
	f.template,
	f.text,
	f.topic,
	f.user_id
  FROM
	:ft_gambit_messages_flattened f
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
	g.carrier_delivered_at,
	g.carrier_failure_code,
	g.platform_message_id,
	g.template,
	g.text,
	g.topic,
	u.northstar_id AS user_id
  FROM
	:ft_gambit_messages_flattened g
  LEFT JOIN
	:ft_gambit_conversations c
	ON g.conversation_id = c._id
  LEFT JOIN
	public.users u
	ON substring(c.platform_user_id, 3, 10) = u.mobile
	AND u.mobile IS NOT NULL
	AND u.mobile <> ''
  WHERE
	g.direction <> 'inbound'
	AND g.user_id IS NULL));

CREATE INDEX ON public.gambit_messages_outbound (message_id, created_at, user_id, conversation_id);
CREATE INDEX deliverability ON public.gambit_messages_outbound (created_at, carrier_failure_code);
GRANT SELECT ON public.gambit_messages_outbound to looker;
GRANT SELECT ON public.gambit_messages_outbound to dsanalyst;
