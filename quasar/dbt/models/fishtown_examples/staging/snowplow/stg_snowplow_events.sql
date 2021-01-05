with 

raw_events as (
    select * from {{ ref('base_snowplow_events') }}
),

parser as (
    select * from {{ ref('base_snowplow_parser_context') }}
),

joined as (
    
    select 
    
        raw_events.*
    
    from raw_events
    left join parser 
        on raw_events.event_id = parser.event_id 
    
    where 
        coalesce (parser.is_excluded_event, FALSE) = FALSE
        -- include only records where exclusion criteria = false, or no match in parser context
        -- DC
        
)

select * from joined