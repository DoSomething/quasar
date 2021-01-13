Hey Team!

This folder contains updates to the snowplow flow. 

I used the [snowplow package](https://github.com/fishtown-analytics/snowplow/tree/0.12.0/) to generate `snowplow_page_views` and `snowplow_sessions`, which are referenced in the corresponding marts models.

# Basic flow:

- `staging/snowplow/base/*` models: stage raw snowplow event-related tables 
- `staging/snowplow/stg_*` models:
  - `stg_snowplow_events` : join the base models into one events models 
  - `stg_snowplow_web_page`: clean web page context models
- `staging/snowplow/intermediate/*`: filter events to structured events, add conversion flags
- `marts/web_analytics`:
  - `fct_snowplow_sessions`: augment package session model with flags in the structured event model 
  - `fct_snowplow_page_views`: augment package page view model with flags - room for more here!


All the package configurations are managed by the dbt project variables set up in `dbt_project.yml`. 

At minimum, the package expects to know the location of the complete events table (`stg_snowplow_events`) and the webpage context table (`stg_snowplow_web_page`). The rest _should_ be handled by the packages - The package also expects columns to be named in their raw form, so I removed renaming in the staging layer.

With the postgres limitations, I haven't been able to 100% verify the accuracy of this code, but the structure should be accurate. 