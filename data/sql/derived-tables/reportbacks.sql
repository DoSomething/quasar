DROP MATERIALIZED VIEW IF EXISTS public.signups_qa CASCADE;
CREATE MATERIALIZED VIEW public.signups_qa AS
    (SELECT
        sd.northstar_id AS northstar_id,
        sd.id AS id,
        sd.campaign_id AS campaign_id,
        sd.campaign_run_id AS campaign_run_id,
        sd.why_participated AS why_participated,
        sd."source" AS "source",
	CASE WHEN sd."source" = 'niche' THEN 'niche'
	     WHEN sd."source" ilike '%%sms%%' THEN 'sms'
	     ELSE 'web' END AS source_bucket,
        sd.created_at AS created_at
    FROM
        (SELECT
        		stemp.id,
        		max(stemp.updated_at) AS updated_at
        FROM rogue.signups stemp
        WHERE stemp.deleted_at IS NULL
        AND stemp."source" IS DISTINCT FROM 'runscope'
        AND stemp."source" IS DISTINCT FROM 'runscope-oauth'
        AND stemp.why_participated IS DISTINCT FROM 'why_participated_ghost'
        GROUP BY stemp.id) s_maxupt
        INNER JOIN rogue.signups sd
            ON sd.id = s_maxupt.id AND sd.updated_at = s_maxupt.updated_at
    )
    ;
CREATE UNIQUE INDEX signupsi ON public.signups_qa (created_at, id);

DROP MATERIALIZED VIEW IF EXISTS public.latest_post_qa CASCADE;
CREATE MATERIALIZED VIEW public.latest_post_qa AS
    (SELECT
	pd.northstar_id as northstar_id,
        pd.id AS id,
        pd."type" AS "type",
        pd."action" AS "action",
        pd.status AS status,
        pd.quantity AS quantity,
        pd."source" AS "source",
        pd.created_at AS created_at,
        pd.url AS url,
        pd.caption,
	CASE WHEN s."source" = 'importer-client'
	     	  AND pd."type" = 'share-social'
		 AND pd.created_at < s.created_at
	     	THEN -1
	     ELSE pd.signup_id END AS signup_id,
	s.campaign_id,
	CASE WHEN pd.id IS NULL THEN NULL
	     WHEN s.campaign_id IN (
	     '822','6223','8103','8119','8129','8130','8180','8195','8202','8208')
	     	  AND s.created_at >= '2018-05-01'
	       THEN 'voter-reg - ground'
	     ELSE CONCAT(pd."type", ' - ', pd."action") END AS post_class
    FROM
        (SELECT
            ptemp.id,
            max(ptemp.updated_at) AS updated_at
         FROM rogue.posts ptemp
         WHERE ptemp.deleted_at IS NULL
         AND ptemp."source" IS DISTINCT FROM 'runscope'
         AND ptemp."source" IS DISTINCT FROM 'runscope-oauth'
        GROUP BY ptemp.id) p_maxupt
     INNER JOIN rogue.posts pd
            ON pd.id = p_maxupt.id AND pd.updated_at = p_maxupt.updated_at
     INNER JOIN public.signups s
     	    ON pd.signup_id = s.id
    )
    ;
CREATE UNIQUE INDEX latest_posti ON public.latest_post_qa (id, created_at);

DROP MATERIALIZED VIEW IF EXISTS public.posts_qa CASCADE;
CREATE MATERIALIZED VIEW public.posts_qa AS
    (SELECT
	    pd.northstar_id as northstar_id,
	    pd.id AS id,
	    pd."type" AS "type",
	    pd."action" AS "action",
	    pd.status AS status,
	    CASE WHEN pd.status IN ('accepted', 'pending')
		    AND post_class NOT ilike 'vote%%' THEN 1
	    	 WHEN pd.status IN ('accepted', 'confirmed', 'register-OVR', 'register-form')
		    AND post_class ilike 'vote%%' THEN 1
		 ELSE null END AS is_accepted,
	    pd.quantity AS quantity,
	    CASE WHEN post_class <> 'voter-reg - ground'
	    	 THEN 1
		 ELSE pd.quantity END AS reportback_volume,
	    pd."source" AS "source",
	    CASE WHEN pd."source" IS NULL THEN NULL
		 WHEN pd."source" ilike '%%sms%%' THEN 'sms'
		 ELSE 'web' END AS source_bucket,
	    COALESCE(rtv.created_at, tv.created_at, pd.created_at) AS created_at,
	    pd.url AS url,
	    pd.caption,
	    pd.signup_id AS signup_id,
	    pd.post_class,
	    pd.campaign_id,
	    CASE WHEN pd.id IS NOT NULL THEN 1
		 ELSE null end as is_reportback
    FROM public.latest_post pd
    LEFT JOIN rogue.turbovote tv ON tv.post_id::bigint = pd.id::bigint
    LEFT JOIN
	(SELECT DISTINCT r.*,
		CASE WHEN r.started_registration < '2017-01-01'
		THEN r.started_registration + interval '4 year'
		ELSE r.started_registration END AS created_at
	FROM rogue.rock_the_vote r
	) rtv ON rtv.post_id::bigint = pd.id::bigint
)
;
CREATE UNIQUE INDEX posti ON public.posts_qa (created_at, campaign_id, id);
CREATE INDEX signup_post_classi on public.posts_qa (is_reportback, is_accepted, signup_id, post_id, post_class);

DROP MATERIALIZED VIEW IF EXISTS public.reportbacks;
CREATE MATERIALIZED VIEW public.reportbacks AS
    (
    SELECT
	pd.id as post_id,
	pd.signup_id,
	pd.campaign_id,
	pd."action" as post_action,
	pd."type" as post_type,
	pd.status as post_status,
	pd.post_class,
	pd.created_at as post_created_at,
	pd.source_bucket as post_source_bucket,
	pd.reportback_volume
    FROM
	public.posts pd
    WHERE pd.id IN (
    	  SELECT min(id)
	  FROM public.posts p
	  WHERE p.is_reportback = 1
	  	 AND p.is_accepted = 1
		 AND p.signup_id != -1
		 AND p.id IS NOT NULL
	  GROUP BY p.signup_id, p.post_class, p.reportback_volume
	  )
)
CREATE UNIQUE INDEX reportbacksi ON public.reportbacks (post_id);
CREATE INDEX created_ati ON public.reportbacks (post_created_at, campaign_id, post_class, reportback_volume);
GRANT SELECT ON public.reportbacks TO looker;
GRANT SELECT ON public.reportbacks TO dsanalyst;
