WITH user_action_metrics AS
  (SELECT u.northstar_id,
          count(CASE
                    WHEN date(m.timestamp) <= date(u.created_at)+ interval '6 month' THEN m.action_type
                END) AS mams_06,
          count(CASE
                    WHEN date(r.post_created_at) <= date(u.created_at)+ interval '6 month' THEN r.post_id
                END) AS rbs_06,
          max(CASE
                  WHEN date(m.timestamp) <= date(u.created_at)+ interval '6 month' THEN date(m.timestamp)
              END) AS last_mam_06,
          count(DISTINCT CASE
                             WHEN date(m.timestamp) <= date(u.created_at)+ interval '6 month' THEN date_trunc('month', m.timestamp)
                         END) AS months_active_06,
          count(CASE
                    WHEN date(m.timestamp) <= date(u.created_at)+ interval '12 month' THEN m.action_type
                END) AS mams_12,
          count(CASE
                    WHEN date(r.post_created_at) <= date(u.created_at)+ interval '12 month' THEN r.post_id
                END) AS rbs_12,
          max(CASE
                  WHEN date(m.timestamp) <= date(u.created_at)+ interval '12 month' THEN date(m.timestamp)
              END) AS last_mam_12,
          count(DISTINCT CASE
                             WHEN date(m.timestamp) <= date(u.created_at)+ interval '12 month' THEN date_trunc('month', m.timestamp)
                         END) AS months_active_12,
          count(CASE
                    WHEN date(m.timestamp) <= date(u.created_at)+ interval '24 month' THEN m.action_type
                END) AS mams_24,
          count(CASE
                    WHEN date(r.post_created_at) <= date(u.created_at)+ interval '24 month' THEN r.post_id
                END) AS rbs_24,
          max(CASE
                  WHEN date(m.timestamp) <= date(u.created_at)+ interval '24 month' THEN date(m.timestamp)
              END) AS last_mam_24,
          count(DISTINCT CASE
                             WHEN date(m.timestamp) <= date(u.created_at)+ interval '24 month' THEN date_trunc('month', m.timestamp)
                         END) AS months_active_24,
          count(CASE
                    WHEN date(m.timestamp) <= date(u.created_at)+ interval '60 month' THEN m.action_type
                END) AS mams_60,
          count(CASE
                    WHEN date(r.post_created_at) <= date(u.created_at)+ interval '60 month' THEN r.post_id
                END) AS rbs_60,
          max(CASE
                  WHEN date(m.timestamp) <= date(u.created_at)+ interval '60 month' THEN date(m.timestamp)
              END) AS last_mam_60,
          count(DISTINCT CASE
                             WHEN date(m.timestamp) <= date(u.created_at)+ interval '60 month' THEN date_trunc('month', m.timestamp)
                         END) AS months_active_60,
          count(m.action_type) AS mams_total,
          count(r.post_id) AS rbs_total,
          max(date(m.timestamp)) AS last_mam_total,
          count(DISTINCT date_trunc('month', m.timestamp)) AS months_active_total
   FROM "quasar_prod_warehouse"."public_intermediate"."campaign_activity_user_created" u
   JOIN
     (SELECT northstar_id,
             action_type,
             action_id,
             to_char(TIMESTAMP, 'YYYY-MM-DD HH:MI:SS:MS') AS time_char,
             min(TIMESTAMP) AS TIMESTAMP
      FROM "quasar_prod_warehouse"."public"."member_event_log"
      WHERE action_type<>'account_creation'
        AND TIMESTAMP >='2008-01-01'
      GROUP BY 1,
               2,
               3,
               4) m ON (u.northstar_id=m.northstar_id)
   LEFT JOIN "quasar_prod_warehouse"."public"."reportbacks" r ON (u.northstar_id=r.northstar_id)
   GROUP BY 1) ,
     calc AS
  (SELECT a.northstar_id,
          created_at,
          extract('year'
                  FROM created_at) AS created_year,
          date_trunc('month', created_at) AS created_month,
          extract(YEAR
                  FROM age(now(), created_at)) AS created_years,
          extract(MONTH
                  FROM age(now(), created_at)) AS created_months,
          coalesce(mams_06, 0) AS mams_06,
          coalesce(rbs_06, 0) AS rbs_06,
          extract(MONTH
                  FROM age(last_mam_06, created_at)) AS last_mam_06_months,
          months_active_06,
          coalesce(mams_12, 0) AS mams_12,
          coalesce(rbs_12, 0) AS rbs_12,
          extract(YEAR
                  FROM age(last_mam_12, created_at)) AS last_mam_12_years,
          extract(MONTH
                  FROM age(last_mam_12, created_at)) AS last_mam_12_months,
          months_active_12,
          coalesce(mams_24, 0) AS mams_24,
          coalesce(rbs_24, 0) AS rbs_24,
          extract(YEAR
                  FROM age(last_mam_24, created_at)) AS last_mam_24_years,
          extract(MONTH
                  FROM age(last_mam_24, created_at)) AS last_mam_24_months,
          months_active_24,
          coalesce(mams_60, 0) AS mams_60,
          coalesce(rbs_60, 0) AS rbs_60,
          extract(YEAR
                  FROM age(last_mam_60, created_at)) AS last_mam_60_years,
          extract(MONTH
                  FROM age(last_mam_60, created_at)) AS last_mam_60_months,
          months_active_60,
          coalesce(mams_total, 0) AS mams_total,
          coalesce(rbs_total, 0) AS rbs_total,
          extract(YEAR
                  FROM age(last_mam_total, created_at)) AS last_mam_total_years,
          extract(MONTH
                  FROM age(last_mam_total, created_at)) AS last_mam_total_months,
          months_active_total
   FROM user_action_metrics a
   JOIN "quasar_prod_warehouse"."public_intermediate"."campaign_activity_user_created" c ON (a.northstar_id=c.northstar_id))
SELECT northstar_id,
       created_at,
       created_year,
       created_month,
       (created_years*12)+created_months AS created_months,
       mams_06,
       rbs_06,
       last_mam_06_months AS last_mam_06,
       months_active_06,
       mams_12,
       rbs_12,
       (last_mam_12_years*12)+last_mam_12_months AS last_mam_12,
       months_active_12,
       mams_24,
       rbs_24,
       (last_mam_24_years*12)+last_mam_24_months AS last_mam_24,
       months_active_24,
       mams_60,
       rbs_60,
       (last_mam_60_years*12)+last_mam_60_months AS last_mam_60,
       months_active_60,
       mams_total,
       rbs_total,
       (last_mam_total_years*12)+last_mam_total_months AS last_mam_total,
       months_active_total
FROM calc