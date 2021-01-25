

  create  table "quasar"."public"."clubs__dbt_tmp"
  as (
    SELECT
	*
FROM
	"quasar"."ft_rogue_dosomething_rogue_qa"."clubs" c
  );