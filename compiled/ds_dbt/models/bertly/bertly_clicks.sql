SELECT
    *,
    (regexp_split_to_array(
        (regexp_split_to_array(
            (regexp_split_to_array(
                c.target_url, 'user')
            -- %3A is the URI Encoded triplet that represents the character ":"
            )[2], E'[=:]+|%3A')
        )[2],
        E'[^a-zA-Z0-9]')
    )[1] AS northstar_id,
    COALESCE(
        (regexp_split_to_array(c.target_url, 'broadcastid=', 'i'))[2],
        (regexp_split_to_array(c.target_url, 'broadcastid_', 'i'))[2],
        (regexp_split_to_array(c.target_url, 'broadcast_id=', 'i'))[2],
        (regexp_split_to_array(c.target_url, 'broadcast_id_', 'i'))[2],
        (regexp_split_to_array(c.target_url, 'broadcast_', 'i'))[2]
            ) AS broadcast_id,
    (CASE WHEN target_url ilike '%source=web%' THEN 'web'
        WHEN target_url ilike '%source=email%' THEN 'email'
        ELSE 'sms'
        END) AS SOURCE,
    CASE
        WHEN c.user_agent IS NULL THEN 'uncertain'
        WHEN c.user_agent ILIKE '%facebot twitterbot%'
                OR c.user_agent ILIKE '%X11; Ubuntu; Linux i686%' THEN 'preview'
        ELSE 'click' END AS interaction_type
FROM "quasar_prod_warehouse"."bertly"."clicks" c