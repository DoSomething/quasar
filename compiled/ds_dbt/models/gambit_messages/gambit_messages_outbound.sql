SELECT
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
    "quasar_prod_warehouse"."public"."messages_flattened" f
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
        "quasar_prod_warehouse"."public"."messages_flattened" g
      LEFT JOIN
        "quasar_prod_warehouse"."ft_gambit_conversations_api"."conversations" c
      ON g.conversation_id = c._id
      LEFT JOIN
        "quasar_prod_warehouse"."public"."users" u
      ON substring(c.platform_user_id, 3, 10) = u.mobile
        AND u.mobile IS NOT NULL
        AND u.mobile <> ''
      WHERE
        g.direction <> 'inbound'
        AND g.user_id IS NULL)