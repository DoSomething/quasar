SELECT northstar_id,
       action_type,
       action_id,
       to_char(TIMESTAMP, 'YYYY-MM-DD HH:MI:SS:MS') AS time_char,
       min(TIMESTAMP) AS TIMESTAMP
FROM "quasar_prod_warehouse"."public"."member_event_log"
WHERE action_type<>'account_creation'
  AND TIMESTAMP >='2008-01-01'
GROUP BY 1, 2, 3, 4