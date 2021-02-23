--All Device ID - Northstar ID Combinations
WITH devices_all AS (
    SELECT device_id, northstar_id
    FROM "quasar_prod_warehouse"."public"."snowplow_raw_events"
    GROUP BY device_id, northstar_id
),
--Devices purely Anonymous (Remove Devices ever associated with NSIDs)
--If a DeviceID was both logged-in and logged-out, it will be removed from the anonymous DeviceID pool
devices_an AS (
    SELECT device_id
    FROM devices_all
    WHERE northstar_id is NULL
    EXCEPT
    SELECT device_id
    FROM devices_all
    WHERE northstar_id IS NOT NULL
),
-- All ND IDs assocaited with DS (to exclude them next)
ds AS (
    SELECT northstar_id
    FROM "quasar_prod_warehouse"."public"."users"
    WHERE lower(email) LIKE '%@dosomething.org'
    GROUP BY northstar_id
),
--Devices owned by NSIDs (DS removed)
devices_ns AS (
    SELECT da.device_id, da.northstar_id
    FROM devices_all da
    LEFT JOIN ds ON (da.northstar_id=ds.northstar_id)
    WHERE da.northstar_id IS NOT NULL
    AND ds.northstar_id is NULL
)
SELECT device_id, northstar_id
FROM devices_ns
UNION ALL
SELECT device_id, NULL
FROM devices_an