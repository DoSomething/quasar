with nps_web_historic as
    (select
      survey_id
      , nps_score
      , (case when nps_score <= 6 then 'detractor'
      	   when nps_score <= 8 then 'passive'
      	   when nps_score <= 10 then 'promoter'
      	   else 'invalid score' end) as net_promoter_cat
      , nps_reason
      , northstar_id
      , surveyed_on_url
      , legacy_campaign_id
      , created_at
   from {{ ref('stg_historical_nps_web') }} )


 , nps_web_current as
    (select
         survey_id
         , nps_score
         , (case when nps_score <= 6 then 'detractor'
        	   when nps_score <= 8 then 'passive'
        	   when nps_score <= 10 then 'promoter'
        	   else 'invalid score' end) as net_promoter_cat
         , nps_reason
         , northstar_id
         , surveyed_on_url
         , null as legacy_campaign_id
         , created_at
      from {{ ref('stg_typeform_nps_web') }} )

, final as
    (select * from nps_web_historic
    	union all
    select * from nps_web_current)

select * from final
