

  create  table "quasar"."public"."groups__dbt_tmp"
  as (
    SELECT
	id,
	group_type_id,
	"name",
	goal,
	created_at,
	updated_at,
	city,
	external_id,
	state,
	school_id
FROM "quasar"."ft_rogue_dosomething_rogue_qa"."groups"
  );