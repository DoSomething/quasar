-- Combines attributes from the ft_snowplow.event and ft_snowplow.snowplow_event schemas
-- removes duplicate events by event_id
SELECT DISTINCT ON (b.event_id, b.event_name, b.event_datetime)
	b.browser_size,
	p.url AS clicked_link_url,
	b.device_id,
	b.event_datetime,
	b.event_id,
	CASE
		WHEN b.event_name IS NULL
		AND b.event_type = 'pv' THEN 'view'
		ELSE b.event_name
	END AS event_name,
	b.event_source,
	b.event_type,
	b."host",
	b.northstar_id,
	b.referrer_host,
	b.referrer_path,
	b.referrer_source,
	b.se_action,
	b.se_category,
	b.se_label,
	b.session_counter,
	b.session_id,
	p.block_id,
	p.campaign_id,
	i.campaign_name,
	p.context_source,
	p.context_value,
	p.group_id,
	p.modal_type,
	b."path",
	p.page_id,
	p.search_query,
	p.utm_campaign,
	p.utm_medium,
	p.utm_source,
    b.query_parameters
  FROM {{ ref('snowplow_base_event') }} b
  LEFT JOIN {{ ref('snowplow_payload_event') }} p ON b.event_id = p.event_id
  LEFT JOIN {{ ref('campaign_info') }} i ON i.campaign_id = p.campaign_id::bigint


{% if is_incremental() %}
  -- this filter will only be applied on an incremental run
  WHERE b.event_datetime >= (select max(sre.event_datetime) from {{this}} sre)
{% endif %}
