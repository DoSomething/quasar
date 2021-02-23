SELECT id AS post_id,
   details::jsonb->>'Tracking Source' AS tracking_source,
   -- is_date_string is a function that checks if the text string value casts
   -- to a timestamptz successfully. It sets the value to NULL if it fails.
   -- Bug Card: https://www.pivotaltracker.com/story/show/176447082
   case when is_date_string(details::jsonb->>'Started registration') is true
    then (details::jsonb->>'Started registration')::timestamp
    else null end AS started_registration,
   case when is_date_string(details::jsonb->>'Started registration') is true
    then (details::jsonb->>'Started registration')::timestamptz
    else null end AS started_registration_utc,
   details::jsonb->>'Finish with State' AS finish_with_state,
   details::jsonb->>'Status' AS status,
   COALESCE(details::jsonb->>'Email address',details::jsonb->>'email') AS email,
   details::jsonb->>'Home zip code' AS zip
 FROM "quasar_prod_warehouse"."ft_dosomething_rogue"."posts"
 WHERE source = 'rock-the-vote'