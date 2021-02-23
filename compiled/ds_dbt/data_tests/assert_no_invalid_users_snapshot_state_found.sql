
with dbt__CTE__INTERNAL_test as (
-- Gets latest user snapshots
WITH latest_updates AS (
    SELECT
        DISTINCT ON(nus."_id") nus."_id",
        nus.email,
        nus.dbt_valid_from,
        nus.dbt_valid_to,
        nus.dbt_scd_id
    FROM
        "quasar_prod_warehouse"."northstar_ft_userapi"."northstar_users_snapshot" nus
    ORDER BY
        nus."_id",
        nus.dbt_valid_from DESC
),
-- filters snapshots that display signs of invalid state:
-- 1. latest snapshot available having a value in "dbt_valid_to"
-- 2. latest user state "updated_at" not matching latest available user snapshot "dbt_valid_from"
affected_users AS (
    SELECT
        u._id,
        lu.dbt_scd_id,
        u.first_name || ' ' || u.last_name AS full_name,
        u.email,
        u.source,
        u.created_at,
        u.updated_at,
        u."_fivetran_synced",
        lu.dbt_valid_from,
        lu.dbt_valid_to
    FROM
        "quasar_prod_warehouse"."northstar_ft_userapi"."users" u
        LEFT JOIN latest_updates lu ON lu._id = u._id
    WHERE
        u.deleted_at IS NULL
        AND lu.dbt_valid_to IS NOT NULL
        AND u.updated_at > lu.dbt_valid_from
)
SELECT
    _id
FROM
    affected_users
)select count(*) from dbt__CTE__INTERNAL_test