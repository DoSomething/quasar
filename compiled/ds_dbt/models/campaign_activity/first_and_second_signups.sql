--first_and_second_signups is the final table referenced used by Looker in 3 views:
--campaign_signups_1_and_2:
--https://dsdata.looker.com/projects/blade/files/campaign_signups_1_and_2.view
--channel_crossover:
--https://dsdata.looker.com/projects/blade/files/channel_crossover.view.lkml
--channel_crossover_campaigns:
--https://dsdata.looker.com/projects/blade/files/channel_crossover_campaigns.view.lkml
--which are used to generate dashboards:
--https://dsdata.looker.com/dashboards/188 (Campaign Sign-Ups 1&2)
--https://dsdata.looker.com/dashboards/208 (User Channel Crossover)
--table first_and_second_signups bring signups 1 & 2 (of the same user) into a single row
--along with previously generated campaign-level data ( campaign_info )
--with the goal of comparing them to determine whether there are patterns
--corresponding to better report-back rates

WITH ns_signups AS (
    SELECT
        id AS signup_id,
        northstar_id,
        campaign_id,
        source_bucket,
        created_at,
        group_id,
        rank() over(
            PARTITION by northstar_id
            ORDER BY
                created_at
        ) nth_signup
    FROM
        "quasar_prod_warehouse"."public"."signups"
),
ns_signup_2 AS (
    SELECT
        *
    FROM
        ns_signups
    WHERE
        nth_signup = 2
)
SELECT
    ns1.northstar_id,
    ns1.campaign_id AS campaign_id_1,
    ns2.campaign_id AS campaign_id_2,
    ns1.signup_id AS signup_id_1,
    ns2.signup_id AS signup_id_2,
    --Sign-Up Source
    ns1.source_bucket AS signup_source_bucket_1,
    ns2.source_bucket AS signup_source_bucket_2,
    CASE
        WHEN NULLIF(ns1.source_bucket, '') IS NULL
        AND NULLIF(ns2.source_bucket, '') IS NULL THEN 'Both are Unknown'
        ELSE concat(
            coalesce(NULLIF(ns1.source_bucket, ''), 'Unknown'),
            ' / ',
            coalesce(NULLIF(ns2.source_bucket, ''), 'Unknown')
        )
    END AS signup_source_bucket_pattern,
    --Action Type from Campaign_Info table
    c1.campaign_action_type AS campaign_action_type_1,
    c2.campaign_action_type AS campaign_action_type_2,
    CASE
        WHEN NULLIF(c1.campaign_action_type, '') IS NULL
        AND NULLIF(c2.campaign_action_type, '') IS NULL THEN 'Both are Unknown'
        WHEN NULLIF(c1.campaign_action_type, '') IS NULL
        OR NULLIF(c2.campaign_action_type, '') IS NULL THEN 'One is Unknown'
        WHEN c1.campaign_action_type LIKE concat('%', c2.campaign_action_type, '%')
        OR c2.campaign_action_type LIKE concat('%', c1.campaign_action_type, '%')
        OR (
            c1.campaign_action_type LIKE '%Donate Something%'
            AND c2.campaign_action_type LIKE '%Donate Something%'
        )
        OR (
            c1.campaign_action_type LIKE '%Make Something%'
            AND c2.campaign_action_type LIKE '%Make Something%'
        )
        OR (
            c1.campaign_action_type LIKE '%Share Something%'
            AND c2.campaign_action_type LIKE '%Share Something%'
        )
        OR (
            c1.campaign_action_type LIKE '%Take a Stand%'
            AND c2.campaign_action_type LIKE '%Take a Stand%'
        ) THEN 'Same'
        ELSE 'Different'
    END AS campaign_action_type_pattern,
    --Action Type from Campaign_Info table
    c1.campaign_cause_type AS campaign_cause_type_1,
    c2.campaign_cause_type AS campaign_cause_type_2,
    CASE
        WHEN NULLIF(c1.campaign_cause_type, '') IS NULL
        AND NULLIF(c2.campaign_cause_type, '') IS NULL THEN 'Both are Unknown'
        WHEN NULLIF(c1.campaign_cause_type, '') IS NULL
        OR NULLIF(c2.campaign_cause_type, '') IS NULL THEN 'One is Unknown'
        WHEN c1.campaign_cause_type LIKE concat('%', c2.campaign_cause_type, '%')
        OR c2.campaign_cause_type LIKE concat('%', c1.campaign_cause_type, '%') THEN 'Same'
        ELSE 'Different'
    END AS campaign_cause_type_pattern,
    --Online/Offline from Campaign_Info table (derived from all RBs for each Campaign ID)
    c1.online_offline AS campaign_online_offline_1,
    c2.online_offline AS campaign_online_offline_2,
    CASE
        WHEN NULLIF(c1.online_offline, '') IS NULL
        AND NULLIF(c2.online_offline, '') IS NULL THEN 'Both are Unknown'
        WHEN c1.online_offline = c2.online_offline THEN concat('Both are ', c1.online_offline)
        ELSE concat(
            coalesce(c1.online_offline, 'Unknown'),
            ' / ',
            coalesce(c2.online_offline, 'Unknown')
        )
    END AS campaign_online_offline_pattern,
    --Action Type from Campaign_Info table (derived from all RBs for each Campaign ID)
    c1.action_types AS campaign_action_types_1,
    c2.action_types AS campaign_action_types_2,
    CASE
        WHEN NULLIF(c1.action_types, '') IS NULL
        AND NULLIF(c2.action_types, '') IS NULL THEN 'Both are Unknown'
        WHEN NULLIF(c1.action_types, '') IS NULL
        OR NULLIF(c2.action_types, '') IS NULL THEN 'One is Unknown'
        WHEN c1.action_types LIKE concat('%', c2.action_types, '%')
        OR c2.action_types LIKE concat('%', c1.action_types, '%') THEN 'Same'
        ELSE 'Different'
    END AS campaign_action_types_pattern,
    --Scholarship from Campaign_Info table (derived from all RBs for each Campaign ID)
    c1.scholarship AS campaign_scholarship_1,
    c2.scholarship AS campaign_scholarship_2,
    CASE
        WHEN NULLIF(c1.scholarship, '') IS NULL
        AND NULLIF(c2.scholarship, '') IS NULL THEN 'Both are Unknown'
        WHEN c1.scholarship = c2.scholarship THEN concat('Both are ', c1.scholarship)
        ELSE concat(
            coalesce(c1.scholarship, 'Unknown'),
            ' / ',
            coalesce(c2.scholarship, 'Unknown')
        )
    END AS campaign_scholarship_pattern,
    --Post Type from Campaign_Info table (derived from all RBs for each Campaign ID)
    c1.post_types AS campaign_post_types_1,
    c2.post_types AS campaign_post_types_2,
    CASE
        WHEN NULLIF(c1.post_types, '') IS NULL
        AND NULLIF(c2.post_types, '') IS NULL THEN 'Both are Unknown'
        WHEN NULLIF(c1.post_types, '') IS NULL
        OR NULLIF(c2.post_types, '') IS NULL THEN 'One is Unknown'
        WHEN c1.post_types LIKE concat('%', c2.post_types, '%')
        OR c2.post_types LIKE concat('%', c1.post_types, '%') THEN 'Same'
        ELSE 'Different'
    END AS campaign_post_types_pattern,
    --Report Backs from Signup 1 & 2 Report Backs
    r1.num_rbs AS num_rbs_1,
    r2.num_rbs AS num_rbs_2,
    CASE
        WHEN coalesce(r1.num_rbs, 0) = 0
        AND coalesce(r2.num_rbs, 0) = 0 THEN 'No RB to Either SignUp'
        WHEN coalesce(r1.num_rbs, 0) = 0 THEN 'No RB to SignUp 1'
        WHEN coalesce(r2.num_rbs, 0) = 0 THEN 'No RB to SignUp 2'
        WHEN r1.num_rbs > 0
        AND r2.num_rbs > 0 THEN 'RB to Both SignUps'
        ELSE '?'
    END AS num_rbs_pattern,
    --Report-Back Source
    r1.post_sources AS rb_source_buckets_1,
    r2.post_sources AS rb_source_buckets_2,
    CASE
        WHEN coalesce(r1.num_rbs, 0) = 0
        AND coalesce(r2.num_rbs, 0) = 0 THEN 'No RB to Either SignUp'
        WHEN coalesce(r1.num_rbs, 0) = 0 THEN concat(
            'No RB',
            ' / ',
            coalesce(r2.post_sources, 'Unknown')
        )
        WHEN coalesce(r2.num_rbs, 0) = 0 THEN concat(
            coalesce(r1.post_sources, 'Unknown'),
            ' / ',
            'No RB'
        )
        ELSE concat(
            coalesce(r1.post_sources, 'Unknown'),
            ' / ',
            coalesce(r2.post_sources, 'Unknown')
        )
    END AS rb_source_buckets_pattern,
    --Report Back Types from Signup 1 & 2 Report Backs
    r1.post_types AS rb_post_types_1,
    r2.post_types AS rb_post_types_2,
    CASE
        WHEN coalesce(r1.num_rbs, 0) = 0
        AND coalesce(r2.num_rbs, 0) = 0 THEN 'No RB to Either SignUp'
        WHEN coalesce(r1.num_rbs, 0) = 0 THEN 'No RB to SignUp 1'
        WHEN coalesce(r2.num_rbs, 0) = 0 THEN 'No RB to SignUp 2'
        WHEN coalesce(r1.post_types, '') = ''
        AND coalesce(r2.post_types, '') = '' THEN 'Both RB Post Types are Unknown'
        WHEN coalesce(r1.post_types, '') = '' THEN 'RB Post Type 1 is Unknown'
        WHEN coalesce(r2.post_types, '') = '' THEN 'RB Post Type 2 is Unknown'
        WHEN r1.post_types LIKE concat('%', r2.post_types, '%')
        OR r2.post_types LIKE concat('%', r1.post_types, '%') THEN 'Same'
        ELSE 'Different'
    END AS rb_post_types_pattern,
    --Report Back Online/Offline from Signup 1 & 2 Report Backs
    r1.online_offline AS rb_online_offline_1,
    r2.online_offline AS rb_online_offline_2,
    CASE
        WHEN coalesce(r1.num_rbs, 0) = 0
        AND coalesce(r2.num_rbs, 0) = 0 THEN 'No RB to Either SignUp'
        WHEN coalesce(r1.num_rbs, 0) = 0 THEN 'No RB to SignUp 1'
        WHEN coalesce(r2.num_rbs, 0) = 0 THEN 'No RB to SignUp 2'
        WHEN coalesce(r1.online_offline, '') = ''
        AND coalesce(r2.online_offline, '') = '' THEN 'Both RB Online/Offline are Unknown'
        WHEN coalesce(r1.online_offline, '') = '' THEN 'RB Online/Offline 1 is Unknown'
        WHEN coalesce(r2.online_offline, '') = '' THEN 'RB Online/Offline 2 is Unknown'
        WHEN r1.online_offline = r2.online_offline THEN concat('Both are ', r1.online_offline)
        ELSE concat(
            coalesce(r1.online_offline, 'Unknown'),
            ' / ',
            coalesce(r2.online_offline, 'Unknown')
        )
    END AS rb_online_offline_pattern,
    --Report Back Action Types from Signup 1 & 2 Report Backs
    r1.action_types AS rb_action_types_1,
    r2.action_types AS rb_action_types_2,
    CASE
        WHEN coalesce(r1.num_rbs, 0) = 0
        AND coalesce(r2.num_rbs, 0) = 0 THEN 'No RB to Either SignUp'
        WHEN coalesce(r1.num_rbs, 0) = 0 THEN 'No RB to SignUp 1'
        WHEN coalesce(r2.num_rbs, 0) = 0 THEN 'No RB to SignUp 2'
        WHEN coalesce(r1.action_types, '') = ''
        AND coalesce(r2.action_types, '') = '' THEN 'Both RB Action Types are Unknown'
        WHEN coalesce(r1.action_types, '') = '' THEN 'RB Action Type 1 is Unknown'
        WHEN coalesce(r2.action_types, '') = '' THEN 'RB Action Type 2 is Unknown'
        WHEN r1.action_types LIKE concat('%', r2.action_types, '%')
        OR r2.action_types LIKE concat('%', r1.action_types, '%') THEN 'Same'
        ELSE 'Different'
    END AS rb_action_types_pattern
FROM
    ns_signups ns1
    LEFT JOIN ns_signup_2 ns2 ON (ns1.northstar_id = ns2.northstar_id)
    JOIN "quasar_prod_warehouse"."public"."campaign_info" c1 ON (ns1.campaign_id = c1.campaign_id :: text)
    LEFT JOIN "quasar_prod_warehouse"."public"."campaign_info" c2 ON (ns2.campaign_id = c2.campaign_id :: text)
    LEFT JOIN "quasar_prod_warehouse"."public"."user_rb_summary" r1 ON (ns1.signup_id = r1.signup_id)
    LEFT JOIN "quasar_prod_warehouse"."public"."user_rb_summary" r2 ON (ns2.signup_id = r2.signup_id)
WHERE
    ns1.nth_signup = 1