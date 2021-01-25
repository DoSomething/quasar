
      

  create  table "quasar"."public"."zendesk_field_history_scd"
  as (
    with change_data as (

    select *
    from "quasar"."public"."zendesk_field_history_pivot"
    

), fill_values as (

    select 
        date_day as valid_from, 
        ticket_id,
        ticket_day_id
        
         
        
        ,last_value(status ignore nulls) over 
          (partition by ticket_id order by date_day asc rows between unbounded preceding and current row) as status

         
        
        ,last_value(assignee_id ignore nulls) over 
          (partition by ticket_id order by date_day asc rows between unbounded preceding and current row) as assignee_id

         
        
        ,last_value(priority ignore nulls) over 
          (partition by ticket_id order by date_day asc rows between unbounded preceding and current row) as priority

        

    from change_data

)

select *
from fill_values
  );
  