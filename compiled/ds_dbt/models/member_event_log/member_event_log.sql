--General approach is to create a long table of events we care about
--We query each data source of interest, manipulate the fields into a consistent format and union
--All the unions go in a subquery which is then pulled into a final top level query
SELECT
    MD5(concat(a.northstar_id, a."timestamp", a.action_id, a.action_serial_id)) AS event_id,
    a.northstar_id,
    a."timestamp" AS "timestamp",
    a."action" AS action_type,
    a.action_id AS action_id,
    a."source" AS "source",
    --This is the unique id of the event from the data source to allow for joining the original data source as needed
    a.action_serial_id AS action_serial_id,
    --This tells us the medium the event occured in e.g. sms, web
    a.channel AS channel,
    --User is new if the month of the timestamp of the action is the same month their account was created
    CASE
        WHEN date_trunc('month', a."timestamp") = date_trunc('month', u.created_at) 
        THEN 'New' 
        ELSE 'Returning' END
        AS "type",
    --This returns the first month the user took an action
    MIN("timestamp")
        OVER
        (PARTITION BY a.northstar_id, date_trunc('month', a."timestamp"))
        AS first_action_month
FROM (
	--Get Campaigns Signups
    SELECT
        DISTINCT s.northstar_id,
        s.created_at AS "timestamp",
        'signup' AS "action",
        '1' AS action_id,
        s."source" AS "source",
        s.id::varchar AS action_serial_id,
        --Bucket signup sources into higher level categories we care about
        (CASE
            WHEN s."source" ILIKE '%sms%' THEN 'sms'
            WHEN s."source" NOT LIKE '%sms%'AND s."source" NOT LIKE '%email%' AND s."source" NOT LIKE '%niche%' OR s."source" IN ('rock-the-vote', 'turbovote') THEN 'web'
            WHEN s."source" ILIKE '%email%' THEN 'email'
            WHEN s."source" ILIKE '%niche%' THEN 'niche_coregistration'
            WHEN s."source" NOT LIKE '%sms%'AND s."source" NOT LIKE '%email%' AND s."source" NOT LIKE '%niche%' AND s."source" NOT IN ('rock-the-vote', 'turbovote') AND s."source" IS NOT NULL THEN 'other' END
            ) AS "channel"
    FROM "quasar_prod_warehouse"."public"."signups" s
    WHERE
    	--Remove voter reg account creations bc we create accounts on users behalf, so they don't constitute active engagement
        s."source" IS DISTINCT FROM 'importer-client'
        AND s."source" IS DISTINCT FROM 'rock-the-vote'
        AND s."source" IS DISTINCT FROM 'turbovote'
    UNION ALL
    --Get Campaigns Posts
    SELECT
        DISTINCT p.northstar_id,
        p.created_at AS "timestamp",
        'post' AS "action",
        '2' AS action_id,
        p."source" AS "source",
        p.id::varchar AS action_serial_id,
        --Calculate channel by grouping post source into higher level categories
        (CASE
            WHEN p."source" ILIKE '%sms%' THEN 'sms'
            WHEN p."source" ILIKE '%phoenix%' OR p."source" IS NULL OR p."source" ILIKE '%turbovote%' THEN 'web'
            WHEN p."source" ILIKE '%app%' THEN 'mobile_app'
            WHEN p."source" NOT LIKE '%phoenix%' AND p."source" NOT LIKE '%sms%' AND p."source" IS NOT NULL AND p."source" NOT LIKE '%app%' AND p."source" NOT LIKE '%turbovote%' THEN 'other' END
            ) AS "channel"
    FROM "quasar_prod_warehouse"."public"."posts" p
    WHERE
    	--We do not want to count certain post types. 
        p.status IN ('accepted', 'confirmed', 'register-OVR', 'register-form', 'pending')
    UNION ALL
    --Site access represents users who were logged in but their auth token refreshed
    SELECT DISTINCT
        u_access.northstar_id,
        u_access.last_accessed_at AS "timestamp",
        'site_access' AS "action",
        '3' AS action_id,
        NULL AS "source",
        '0' AS action_serial_id,
        'web' AS channel
    FROM "quasar_prod_warehouse"."public"."northstar_users_deduped" u_access
    WHERE
    	--Remove test accounts
        u_access.last_accessed_at IS NOT NULL
        AND u_access."source" IS DISTINCT FROM 'runscope'
        AND u_access."source" IS DISTINCT FROM 'runscope-client'
        AND u_access.email IS DISTINCT FROM 'runscope-scheduled-test@dosomething.org'
        AND u_access.email IS DISTINCT FROM 'juy+runscopescheduledtests@dosomething.org'
        AND (u_access.email NOT ILIKE '%@example.org%' OR u_access.email IS NULL)
    UNION ALL
    --Get site authentications
    SELECT DISTINCT
        u_login.northstar_id,
        u_login.last_authenticated_at AS "timestamp",
        'site_login' AS "action",
        '4' AS action_id,
        NULL AS "source",
        '0' AS action_serial_id,
        'web' AS channel
    FROM "quasar_prod_warehouse"."public"."northstar_users_deduped" u_login
    WHERE
    	--Remove test records
        u_login.last_authenticated_at IS NOT NULL
        AND u_login."source" IS DISTINCT FROM 'runscope'
        AND u_login."source" IS DISTINCT FROM 'runscope-client'
        AND u_login.email IS DISTINCT FROM 'runscope-scheduled-test@dosomething.org'
        AND u_login.email IS DISTINCT FROM 'juy+runscopescheduledtests@dosomething.org'
        AND (u_login.email NOT ILIKE '%@example.org%' OR u_login.email IS NULL)
    UNION ALL
    --Get account creations
    SELECT
        DISTINCT u.northstar_id,
        u.created_at AS "timestamp",
        'account_creation' AS action,
        '5' AS action_id,
        u."source" AS "source",
        '0' AS action_serial_id,
        --Bucket channel into higher level categories
        (CASE
            WHEN u."source" ILIKE '%sms%' THEN 'sms'
            WHEN u."source" ILIKE '%phoenix%' OR u."source" IS NULL THEN 'web'
            WHEN u."source" ILIKE '%niche%' THEN 'niche_coregistration'
            WHEN u."source" NOT LIKE '%niche%' AND u."source" NOT LIKE '%sms%' AND u."source" NOT LIKE '%phoenix%' AND u."source" IS NOT NULL THEN 'other' END
            ) AS "channel"
    FROM
        (SELECT
            u_create.northstar_id,
            max(u_create."source") AS "source",
            min(u_create.created_at) AS created_at
        FROM "quasar_prod_warehouse"."public"."northstar_users_deduped" u_create
        WHERE
        	--Remove voter reg created accounts bc we create the account on behalf of the user
            u_create."source" IS DISTINCT FROM 'importer-client'
            --Remove test records
            AND u_create."source" IS DISTINCT FROM 'runscope'
            AND u_create."source" IS DISTINCT FROM 'runscope-client'
            AND u_create.email IS DISTINCT FROM 'runscope-scheduled-test@dosomething.org'
            AND u_create.email IS DISTINCT FROM 'juy+runscopescheduledtests@dosomething.org'
            AND (u_create.email NOT ILIKE '%@example.org%' OR u_create.email IS NULL)
        GROUP BY u_create.northstar_id
        ) u
    UNION ALL
    --Get inbound SMS messages recorded by Gambit
    SELECT
        DISTINCT g.user_id AS northstar_id,
        g.created_at AS "timestamp",
        'messaged_gambit' AS "action",
        '6' AS action_id,
        'SMS' AS "source",
        g.message_id AS action_serial_id,
        'sms' AS "channel"
    FROM "quasar_prod_warehouse"."public"."gambit_messages_inbound" g
    WHERE
    	--Remove records with no recorded NSID
        g.user_id IS NOT NULL
        --Remove messages where the user requested we stop sending messages
        AND g.macro <> 'subscriptionStatusStop'
    UNION ALL
    --Get clicks on links within emails we sent as logged by customer.io
    SELECT
        DISTINCT cio.customer_id AS northstar_id,
        cio."timestamp" AS "timestamp",
        'clicked_link' AS "action",
        '7' AS action_id,
        cio.template_id::CHARACTER AS "source",
        cio.event_id AS action_serial_id,
        'email' AS "channel"
    FROM
        "quasar_prod_warehouse"."public"."cio_email_events" cio
    WHERE
    	--Filter to clicks within emails event log
        cio.event_type = 'email_clicked'
        AND cio.customer_id IS NOT NULL
    UNION ALL
    --Get shortlink resolution events as logged by Bertly
    SELECT DISTINCT
        b.northstar_id,
        b.click_time AS "timestamp",
        CONCAT('bertly_link_', b.interaction_type) AS "action",
        '10' AS action_id,
        'bertly' AS "source",
        b.click_id AS action_serial_id,
        b."source" AS "channel"
    FROM "quasar_prod_warehouse"."public"."bertly_clicks" b
    INNER JOIN "quasar_prod_warehouse"."public"."users" u
        ON b.northstar_id = u.northstar_id
    WHERE
    	--Must have nsid to count
        b.northstar_id IS NOT NULL
        --Only link clicks count, not link previews which can generate automatically
        AND b.interaction_type IS DISTINCT FROM 'preview'
) AS a
LEFT JOIN "quasar_prod_warehouse"."public"."users" u ON u.northstar_id = a.northstar_id