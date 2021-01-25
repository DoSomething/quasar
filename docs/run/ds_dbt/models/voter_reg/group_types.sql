

  create  table "quasar"."public"."group_types__dbt_tmp"
  as (
    SELECT
	id,
	"name",
	created_at,
	updated_at,
	filter_by_state
FROM "quasar"."ft_rogue_dosomething_rogue_qa"."group_types"
  );