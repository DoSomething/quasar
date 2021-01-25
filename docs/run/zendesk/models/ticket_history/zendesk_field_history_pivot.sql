
      

  create  table "quasar"."public"."zendesk_field_history_pivot"
  as (
    


    
with field_history as (

    select *
    from "quasar"."public"."stg_zendesk_ticket_field_history"
    

), event_order as (

    select 
        *,
        row_number() over (
            partition by cast(valid_starting_at as date), ticket_id, field_name
            order by valid_starting_at desc
            ) as row_num
    from field_history

), filtered as (

    -- Find the last event that occurs on each day for each ticket

    select *
    from event_order
    where row_num = 1

), pivot as (

    -- For each column that is in both the ticket_field_history_columns variable and the field_history table,
    -- pivot out the value into it's own column. This will feed the daily slowly changing dimension model.

    select 
        ticket_id,
        cast(

    valid_starting_at + ((interval '1 day') * (0))

 as date) as date_day

        
        
        , min(case when lower(field_name) = 'status' then value end) as status
        
        
        , min(case when lower(field_name) = 'assignee_id' then value end) as assignee_id
        
        
        , min(case when lower(field_name) = 'priority' then value end) as priority
        
    
    from filtered
    where cast(valid_starting_at as date) < current_date
    group by 1,2

), surrogate_key as (

    select 
        *,
        md5(cast(concat(coalesce(cast(ticket_id as 
    varchar
), ''), '-', coalesce(cast(date_day as 
    varchar
), '')) as 
    varchar
)) as ticket_day_id
    from pivot

)

select *
from surrogate_key
  );
  