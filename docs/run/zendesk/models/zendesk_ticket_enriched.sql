

  create  table "quasar"."public"."zendesk_ticket_enriched__dbt_tmp"
  as (
    -- this model enriches the ticket table with ticket-related dimensions.  This table will not include any metrics.
-- for metrics, see ticket_metrics!

with  __dbt__CTE__ticket_tags as (
with ticket_tags as (

    select *
    from "quasar"."public"."stg_zendesk_ticket_tag"
  
)

select
  ticket_tags.ticket_id,
  
    string_agg(ticket_tags.tags, ', ')

 as ticket_tags
from ticket_tags
group by 1
),ticket as (

    select *
    from "quasar"."public"."stg_zendesk_ticket"

), users as (

    select *
    from "quasar"."public"."stg_zendesk_user"

), ticket_group as (
    
    select *
    from "quasar"."public"."stg_zendesk_group"

), organization as (

    select *
    from "quasar"."public"."stg_zendesk_organization"

), ticket_tags as (

    select *
    from __dbt__CTE__ticket_tags

), joined as (

    select 

        ticket.*,
        requester.role as requester_role,
        requester.email as requester_email,
        requester.name as requester_name,
        submitter.role as submitter_role,
        submitter.email as submitter_email,
        submitter.name as submitter_name,
        assignee.role as assignee_role,
        assignee.email as assignee_email,
        assignee.name as assignee_name,
        ticket_group.name as group_name,
        organization.name as organization_name,
        ticket_tags.ticket_tags

    
    from ticket

    join users as requester
        on requester.user_id = ticket.requester_id
    
    join users as submitter
        on submitter.user_id = ticket.submitter_id
    
    left join users as assignee
        on assignee.user_id = ticket.assignee_id

    left join ticket_group
        on ticket_group.group_id = ticket.group_id

    left join organization
        on organization.organization_id = ticket.organization_id

    left join ticket_tags
        on ticket_tags.ticket_id = ticket.ticket_id
)

select *
from joined
  );