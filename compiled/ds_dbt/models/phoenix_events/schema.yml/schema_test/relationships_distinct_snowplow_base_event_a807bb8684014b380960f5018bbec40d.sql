
    SELECT
        count(DISTINCT a.northstar_id) AS orphan_ids
    FROM
        "quasar_prod_warehouse"."public"."snowplow_base_event" a
        LEFT JOIN "quasar_prod_warehouse"."public"."users" b ON a.northstar_id = b.northstar_id
    WHERE
        a.northstar_id IS NOT NULL
        AND b.northstar_id IS NULL
