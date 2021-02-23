SELECT 
  cmr.contentful_id,
  (cmr.fields #>>'{legacy_campaign_id}')::INT AS legacy_campaign_id,
  cmr.fields #>>'{internal_title}' AS internal_title,
  cmr.fields #>>'{title}' AS title,
  cmr.fields #>>'{slug}' AS  slug, 
  cmr.fields #>>'{display_referral_page}' AS display_referral_page
FROM "quasar_prod_warehouse"."public_intermediate"."contentful_metadata_raw" cmr