

  create  table "quasar"."public"."campaign_info_international__dbt_tmp"
  as (
    SELECT
	c.id AS campaign_id,
	c.internal_title AS campaign_name,
	i.*
FROM "quasar"."public"."campaign_info_ashes_snapshot" i
LEFT JOIN "quasar"."ft_rogue_dosomething_rogue_qa"."campaigns" c ON i.campaign_run_id = c.campaign_run_id
WHERE campaign_language IS DISTINCT FROM 'en'
  );