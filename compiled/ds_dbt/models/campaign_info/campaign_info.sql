WITH
--Campaigns with Online/Offline Post Components
campaign_online AS (
  SELECT
    campaign_id,
    -- Uses distinct count to check if
    -- there is only online or only offline actions (Value would be 1)
    -- there is a mix of online and offline (Value would be 2)
    count(DISTINCT online) AS online_count,
    -- If the campaign has only 1 action, min_online will hold "Online" or "Offline" accordingly.
    -- If the campaign has any number of both types of actions min_online will always hold "Offline"
    -- NOTE: Ignore in that case.
    min(
      CASE
        WHEN online = TRUE THEN 'Online'
        ELSE 'Offline'
      END
    ) AS min_online
  FROM
    "quasar_prod_warehouse"."public"."post_actions"
  GROUP BY
    1
),
campaign_online_combo AS (
  SELECT
    campaign_id,
    CASE
      WHEN online_count > 1 THEN 'Both'
      ELSE min_online
    END AS online_offline
  FROM
    campaign_online
),
--Campaigns and Action Types
campaign_action AS (
  SELECT campaign_id, action_type
  FROM "quasar_prod_warehouse"."public"."post_actions"
  WHERE action_type IS NOT null AND action_type<>''
  GROUP BY 1, 2
),
--Campaigns and Action Types Combined
campaign_action_combo AS (
    SELECT campaign_id, string_agg(action_type, ' , ' ORDER BY action_type) AS action_types
    FROM campaign_action
    GROUP BY 1
),
-- Campaigns and Scholarship
campaign_scholarship AS (
  SELECT campaign_id, count(CASE WHEN scholarship_entry=true THEN 1 END) AS scholarship
  FROM "quasar_prod_warehouse"."public"."post_actions"
  GROUP BY 1
),
-- Campaigns and Scholarship Combined
campaign_scholarship_combo AS (
    SELECT campaign_id, (CASE WHEN scholarship>0 THEN 'Scholarship' ELSE 'Not Scholarship' END) AS scholarship
    FROM campaign_scholarship
),
--Campaigns and Action Types
campaign_post_type AS (
  SELECT campaign_id, post_type
  FROM "quasar_prod_warehouse"."public"."post_actions"
  WHERE post_type IS NOT null AND post_type<>''
  GROUP BY 1, 2
),
--Campaigns and Action Types Combined
campaign_post_type_combo AS (
    SELECT campaign_id, string_agg(post_type, ' , ' ORDER BY post_type) AS post_types
    FROM campaign_post_type
    GROUP BY 1
)
SELECT 
	c.id AS campaign_id,
	c.campaign_run_id,
	c.internal_title AS campaign_name,
	c.cause AS campaign_cause,
	c.start_date AS campaign_run_start_date,
	c.end_date AS campaign_run_end_date,
	c.created_at AS campaign_created_date,
	COALESCE(i.campaign_node_id, c.id) AS campaign_node_id,
  c.group_type_id,
  cm.contentful_id as contentful_id,
  cm.internal_title as contentful_internal_title,
  cm.title as contentful_title,
  cm.display_referral_page as contentful_RAF_flag,
	i.campaign_node_id_title,
	i.campaign_run_id_title,
	CASE WHEN i.campaign_action_type = '' THEN null ELSE i.campaign_action_type END AS campaign_action_type,
	COALESCE(
		CASE WHEN c.cause = '' THEN null ELSE c.cause END,
		CASE WHEN i.campaign_cause_type = '' THEN null ELSE i.campaign_cause_type END
	) AS campaign_cause_type,
	i.campaign_noun,
	i.campaign_verb,
	i.campaign_cta,
	CASE WHEN a.action_types = '' THEN null ELSE a.action_types END AS action_types,
	o.online_offline,
	s.scholarship,
	p.post_types
FROM "quasar_prod_warehouse"."ft_dosomething_rogue"."campaigns" c
LEFT JOIN "quasar_prod_warehouse"."public"."campaign_info_ashes_snapshot" i ON i.campaign_run_id = c.campaign_run_id
LEFT JOIN campaign_action_combo a on c.id = a.campaign_id
LEFT JOIN campaign_online_combo o on c.id = o.campaign_id
LEFT JOIN campaign_scholarship_combo s on c.id = s.campaign_id
LEFT JOIN campaign_post_type_combo p on c.id = p.campaign_id
LEFT JOIN "quasar_prod_warehouse"."public_intermediate"."contentful_metadata" cm on c.id = cm.legacy_campaign_id
WHERE i.campaign_language = 'en' OR i.campaign_language IS null