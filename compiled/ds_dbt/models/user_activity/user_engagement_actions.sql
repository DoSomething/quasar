WITH user_mams AS
  (SELECT northstar_id,
          action_type,
          TIMESTAMP,
          rank() over(PARTITION BY northstar_id
                      ORDER BY time_char, action_id) AS nth_action
   FROM "quasar_prod_warehouse"."public_intermediate"."user_actions")
SELECT u.northstar_id,
       action_type,
       nth_action,
       CASE
           WHEN date(m.timestamp) <= date(u.created_at)+ interval '6 month' THEN 6
           WHEN date(m.timestamp) <= date(u.created_at)+ interval '12 month' THEN 12
           WHEN date(m.timestamp) <= date(u.created_at)+ interval '24 month' THEN 24
           WHEN date(m.timestamp) <= date(u.created_at)+ interval '60 month' THEN 60
       END AS action_within
FROM "quasar_prod_warehouse"."public_intermediate"."campaign_activity_user_created" u
JOIN user_mams m ON (u.northstar_id=m.northstar_id)
WHERE nth_action <=10