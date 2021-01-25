
      

  create  table "quasar"."public"."zendesk_field_calendar_spine"
  as (
    

with  __dbt__CTE__zendesk_calendar_spine as (
-- depends_on: "quasar"."public"."stg_zendesk_ticket"

with spine as (

    
    
    
    
    



/*
call as follows:

date_spine(
    "day",
    "to_date('01/01/2016', 'mm/dd/yyyy')",
    "dateadd(week, 1, current_date)"
)

*/

with rawdata as (

    

    

    with p as (
        select 0 as generated_number union all select 1
    ), unioned as (

    select

    
    p0.generated_number * pow(2, 0)
     + 
    
    p1.generated_number * pow(2, 1)
     + 
    
    p2.generated_number * pow(2, 2)
     + 
    
    p3.generated_number * pow(2, 3)
     + 
    
    p4.generated_number * pow(2, 4)
     + 
    
    p5.generated_number * pow(2, 5)
     + 
    
    p6.generated_number * pow(2, 6)
     + 
    
    p7.generated_number * pow(2, 7)
     + 
    
    p8.generated_number * pow(2, 8)
     + 
    
    p9.generated_number * pow(2, 9)
     + 
    
    p10.generated_number * pow(2, 10)
     + 
    
    p11.generated_number * pow(2, 11)
    
    
    + 1
    as generated_number

    from

    
    p as p0
     cross join 
    
    p as p1
     cross join 
    
    p as p2
     cross join 
    
    p as p3
     cross join 
    
    p as p4
     cross join 
    
    p as p5
     cross join 
    
    p as p6
     cross join 
    
    p as p7
     cross join 
    
    p as p8
     cross join 
    
    p as p9
     cross join 
    
    p as p10
     cross join 
    
    p as p11
    
    

    )

    select *
    from unioned
    where generated_number <= 2572
    order by generated_number



),

all_periods as (

    select (
        

    '2014-01-13' + ((interval '1 day') * (row_number() over (order by 1) - 1))


    ) as date_day
    from rawdata

),

filtered as (

    select *
    from all_periods
    where date_day <= 

    current_date + ((interval '1 week') * (1))



)

select * from filtered



), recast as (

    select cast(date_day as date) as date_day
    from spine

)

select *
from recast
),calendar as (

    select *
    from __dbt__CTE__zendesk_calendar_spine
    

), ticket as (

    select *
    from "quasar"."public"."stg_zendesk_ticket"
    
), joined as (

    select 
        calendar.date_day,
        ticket.ticket_id
    from calendar
    inner join ticket
        on calendar.date_day >= cast(ticket.created_at as date)

), surrogate_key as (

    select
        *,
        md5(cast(concat(coalesce(cast(date_day as 
    varchar
), ''), '-', coalesce(cast(ticket_id as 
    varchar
), '')) as 
    varchar
)) as ticket_day_id
    from joined

)

select *
from surrogate_key
  );
  