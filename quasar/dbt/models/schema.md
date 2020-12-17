
{% docs block_id %}
References specific content blocks from contentful CMS, PMs decide whether its important to send that info with specific click events.
{% enddocs %}

{% docs context_source %}
We use this to denote the 'context' for events that can be triggered from different locations in the app. (It'll be a string like campaign_landing_page or scholarship_modal).

e.g. the 'clicked_signup' event can come from wherever we embed a campaign signup form which happens in a modal, or on the landing page itself. (So helpful for analytics to determine which specific form is driving the signup).
{% enddocs %}

{% docs context_value %}
This property is available to add more context to certain events (e.g. cause value selected when filtering campaigns by cause). It is vague enough that testing of when we should get this value is not practical. Consult with PMs for specific context when this field exists.
{% enddocs %}

{% docs group_id %}
Unique identifier for groups. Group id is tied to work for volunteer credits and online voter drives (members can participate as part of a group)... product managers can choose to send web events with the group_id where its relevant. (right now it's being used for Online voter registration groups, but in the future it could be used for other types of group related efforts, e.g. volunteer hours).

Included only with "clicked_group_finder_group" events. This may change in the future. Consult with PMs for use of this property in other events.
{% enddocs %}

{% docs search_query %}
Term associated with any search events. Sent when the user submits a search term in the search bar.
{% enddocs %}

{% docs click_id %}
This is a unique identifier for each click
{% enddocs %}

{% docs click_time %}
Timestamp when user clicked.
{% enddocs %}

{% docs shortened %}
Shortened URL
{% enddocs %}

{% docs target_url %}
URL where the user will be directed
{% enddocs %}

{% docs broadcast_id %}
ID of the broadcast that generated the shortened URL
{% enddocs %}

{% docs source %}
Source of the URL (e.g. SMS, web), origin of the post (e.g. phoenix-web, phoenix-ashes, sms), or source where user was acquired. (e.g. sms, phoenix-next)
{% enddocs %}

{% docs post_source_buckets %}
Aggregated list of the grouping buckets for the origin of the posts (e.g. sms, web)
{% enddocs %}

{% docs post_types %}
Aggregated list of post types of the posts (e.g. photo, phone-call, share-social, text, voter-reg, email)
{% enddocs %}

{% docs campaign_post_types %}
Aggregated list of post types of all the actions available for the campaign (e.g. photo, phone-call, share-social, text, voter-reg, email)
{% enddocs %}

{% docs interaction_type %}
How the user interacted with the link (e.g. preview, click)
{% enddocs %}

{% docs id %}
Unique identifier for the post
{% enddocs %}

{% docs type %}
Type of post (e.g. photo)
{% enddocs %}

{% docs action %}
Post action (e.g. DefendDreamers_Nov9_CongressCalls, GunViolence2018_Feb15_ParklandResponse)
{% enddocs %}

{% docs status %}
Post status (e.g. accepted, rejected)
{% enddocs %}

{% docs quantity %}
Numerical quantity of items specified in the call to action (e.g. 10, 200)
{% enddocs %}

{% docs source_bucket %}
Grouping bucket for the origin of the post (e.g. web, sms)
{% enddocs %}

{% docs created_at %}
When the item was created in UTC (eg. 2018-01-01 12:00:00)
{% enddocs %}

{% docs updated_at %}
When the item was updated in UTC (eg. 2018-01-01 12:00:00)
{% enddocs %}

{% docs text %}
Text of the post (e.g. "Zoo animals and a super hero trying to help too!") 
{% enddocs %}

{% docs signup_id %}
Unique identifier for the signup
{% enddocs %}

{% docs post_class %}
Class of the signup (e.g. "photo - default", "phone-call - DefendDreamers_Jan16_BothBodies")
{% enddocs %}

{% docs is_accepted %}
Whether the post has been accepted to be displayed to the public on the website
{% enddocs %}

{% docs action_id %}
Internal identifier of the campaign action
{% enddocs %}

{% docs location %}
Location where the action takes place (e.g. US-NY)
{% enddocs %}

{% docs postal_code %}
Postal code where the action takes place
{% enddocs %}

{% docs is_reportback %}
Whether the post is a reportback. The application allows for multiple types of posts.
{% enddocs %}

{% docs civic_action %}
Whether the post is a Civic Action. The application allows for multiple types of posts.
{% enddocs %}

{% docs scholarship_entry %}
Whether the post is a Scholarship Entry. The application allows for multiple types of posts.
{% enddocs %}

{% docs why_participated %}
Why the user participated in this action. Entered by the user.
{% enddocs %}

{% docs details %}
Details about the post. Contains contentfulId and other information (e.g. {"campaignContentfulId":"6ATBgGEQEeJoIcxs1qbwaC"})
{% enddocs %}

{% docs email %}
Email address of the user.
{% enddocs %}

{% docs source_details %}
Details about the source of the item. This is sometimes represented as a JSON object, and for other tables like Turbovote its represented as a string. (e.g. "{"contentful_id":"3CTLlXfbwtz1FOMpl31SKV","utm_source":"scholarship_listing","utm_medium":"referral","utm_campaign":"fastweb_2019_08"}", newsletter_456)
{% enddocs %}

{% docs campaign_id %}
This is a unique identifier for the campaign
{% enddocs %}

{% docs internal_campaign_id %}
Internal DoSomething Campaign ID. Not present on all web visits (ex. the homepage is not tied to a campaign_id).
{% enddocs %}

{% docs campaign_run_id %}
Unique identifier for the campaign run
{% enddocs %}

{% docs campaign_name %}
Name of the campaign
{% enddocs %}

{% docs campaign_cause %}
Campaign cause (eg. Mental Health, Education)
{% enddocs %}

{% docs campaign_run_start_date %}
Start date of the campaign run
{% enddocs %}

{% docs campaign_run_end_date %}
End date of the campaign run
{% enddocs %}

{% docs campaign_created_date %}
When the campaign was created in UTC (eg. 2018-01-01 12:00:00)
{% enddocs %}

{% docs campaign_node_id %}
Internal unique node id for the campaign
{% enddocs %}

{% docs campaign_node_id_title %}
Campaign title
{% enddocs %}

{% docs campaign_run_id_title %}
Title of the campaign run
{% enddocs %}

{% docs campaign_action_type %}
Campaign action type (eg. Make Something, Share Something)
{% enddocs %}

{% docs post_action_types %}
Aggregated list of Action Types of the Posts (e.g. attend-event, share-something, make-something, collect-something, contact-decisionmaker, donate-something, host-event, have-a-conversation, flag-content, sign-petition, submit-tip, other)
{% enddocs %}

{% docs campaign_action_types %}
Aggregated list of Action Types of all the Actions available for the campaign (e.g. attend-event, share-something, make-something, collect-something, contact-decisionmaker, donate-something, host-event, have-a-conversation, flag-content, sign-petition, submit-tip, other)
{% enddocs %}

{% docs campaign_cause_type %}
Campaign cause type (e.g. Mental Health, Education, Environment)
{% enddocs %}

{% docs campaign_noun %}
Noun applicable to the user's action
{% enddocs %}

{% docs campaign_verb %}
Verb describing the action the user should take
{% enddocs %}

{% docs campaign_cta %}
Campaign's call to action
{% enddocs %}

{% docs campaign_language %}
"Language in which the campaign is available"
{% enddocs %}

{% docs agent_id %}
If set, the content type of the picture the member is sending us. Exp. image/png.
{% enddocs %}

{% docs attachment_content_type %}
If set, the handle of the Front agent this outbound support message is from.
{% enddocs %}

{% docs topic %}
Holds a reference to the **last** campaign topic the member's conversation was in. This is useful to allow members to talk to Gambit and get quick responses (through Rivescript), without Gambit completely forgetting what state the member's interaction with a campaign topic was in.
{% enddocs %}

{% docs action_serial_id %}
Serial id for the user's action. Depends on the source of the action. May be the bertly click id, sms message id, etc.
{% enddocs %}

{% docs channel %}
Channel for the user's action. Depends on the source of the action. (e.g. web, sms)
{% enddocs %}

{% docs first_action_month %}
Month during which the user took their first action.
{% enddocs %}

{% docs event_id %}
This is a unique identifier for each event
{% enddocs %}

{% docs event_source %}
Application source for event (eg. Phoenix, Northstar)
{% enddocs %}

{% docs event_datetime %}
When the event occurred in UTC (eg. 2018-01-01 12:00:00)
{% enddocs %}

{% docs event_name %}
Name of the event (eg. northstar_submitted_register, https://docs.google.com/spreadsheets/d/1lm-fGrIm85nUTxSojqyCt_Ehmm1zEbViFhKpxcJiz1A/edit#gid=406441516)
{% enddocs %}

{% docs event_type %}
Type of event (pv = 'Page View', se = 'Structured Event')
{% enddocs %}

{% docs host %}
URL host where event occurred (eg. www.dosomething.org or identity.dosomething.org)
{% enddocs %}

{% docs path %}
URL path event occurred at (eg. /login or /us/campaigns/huddle-for-heroes)
{% enddocs %}

{% docs query_parameters %}
Optional query parameters for the request (eg. query=huddle)
{% enddocs %}

{% docs se_category %}
Category of event (eg. focused_field, authentication) - Snowplow Custom structured event. (Required for event type "se")
{% enddocs %}

{% docs se_action %}
Action performed / event name (eg. form_submitted, action_failed) - Snowplow Custom structured event. (Required for event type "se")
{% enddocs %}

{% docs se_label %}
The object of the action (eg. first_name, register, voter_reg_status) - Snowplow Custom structured event. (Required for event type "se")
{% enddocs %}

{% docs session_id %}
Unique identifier of the user's session. This is how we associate all events in a visit.
{% enddocs %}

{% docs session_counter %}
How many sessions a user has started. This is how we associate new vs. returning visits.
{% enddocs %}

{% docs browser_size %}
Which type of browser a user is using (eg. Mobile, Desktop). This is default metadata sent from browser, it won't always be present.
{% enddocs %}

{% docs northstar_id %}
The Northstar ID of the user who generated the event.
{% enddocs %}

{% docs device_id %}
ID of the device used
{% enddocs %}

{% docs referrer_host %}
URL host of the referring site (eg. google.com). Only present if session is referred from some external site link (ex. Facebook, Google, Bing). This would be NULL for anyone directly typing dosomething.org into a browser
{% enddocs %}

{% docs referrer_path %}
URL path from referring site (eg. /10-stats-on-teen-drug-and-alcohol-use/). Only present if session is referred from some external site link (ex. Facebook, Google, Bing).
{% enddocs %}

{% docs referrer_source %}
Referrer source name (eg. Google, Facebook). Only present if session is referred from some external site link (ex. Facebook, Google, Bing).
{% enddocs %}

{% docs utm_source %}
Tracks where the traffic is coming from. (eg. scholarship_listing, Facebook). Parameter passed by marketing team (would not be present for organic/ direct traffic)
{% enddocs %}

{% docs utm_medium %}
How the traffic got to the platform (eg. referral, CPC). Parameter passed by marketing team (would not be present for organic/ direct traffic)
{% enddocs %}

{% docs utm_campaign %}
Tracks which campaign the traffic was generated by. Shows up in Google Analytics as Campaign Name (eg. editorial_newsletter). Parameter passed by marketing team (would not be present for organic/ direct traffic)
{% enddocs %}

{% docs posts_url %}
URL of campaign (eg. https://dosome.click/nyn5m7)
{% enddocs %}

{% docs click_event_url %}
This "url" is included in some events. Not all events with a name containing "clicked" will have "url" included. Consult with PMs for context specific to a certain event.
{% enddocs %}

{% docs modal_type %}
Certain pages have modals and therefore certain event actions will have it (e.g. NULL or SURVEY_MODAL). Included with "opened_modal" or "closed_modal" events.
{% enddocs %}

{% docs landing_datetime %}
Timestamp of when the session started, in UTC (eg. 2018-01-01 12:00:00)
{% enddocs %}

{% docs ending_datetime %}
Timestamp of when the session ended, in UTC (eg. 2018-01-01 12:00:00)
{% enddocs %}

{% docs session_duration_seconds %}
Session duration in seconds.
{% enddocs %}

{% docs num_pages_viewed %}
Number of view events in this session.
{% enddocs %}

{% docs landing_page %}
First page the user viewed in the session (eg. /us/facts/11-facts-about-bp-oil-spill)
{% enddocs %}

{% docs exit_page %}
Which page the user ended or exited their session from (eg. /us/campaigns/green-your-getaway)
{% enddocs %}

{% docs days_since_last_session %}
"Days since their last session."
{% enddocs %}

{% docs post_type %}
Type of post, (e.g. photo, voter-reg)
{% enddocs %}

{% docs noun %}
Noun that corresponds to the item in the call to action that was delivered. (e.g. drawings, tweets)
{% enddocs %}

{% docs verb %}
Verb corresponding to the action the user took. (e.g. shared, sent, taken)
{% enddocs %}

{% docs deleted_at %}
Date time in UTC when a user deleted their post.
{% enddocs %}

{% docs _fivetran_deleted %}
Marks rows that were deleted in the source table
{% enddocs %}

{% docs _fivetran_synced %}
(UTC timestamp) keeps track of when each row was last successfully synced
{% enddocs %}

{% docs reportback %}
Whether the post is a reportback 
{% enddocs %}

{% docs active %}
Whether the user is active 
{% enddocs %}

{% docs anonymous %}
Whether the user is anonymous when making the post 
{% enddocs %}

{% docs callpower_campaign_id %}
Unique ID corresponding to the Callpower campaign. Callpower allows users to record messages for their representatives.
{% enddocs %}

{% docs quiz %}
Whether the post is a quiz 
{% enddocs %}

{% docs action_type %}
Type of action the user took. (e.g. share-something, donate-something)
{% enddocs %}

{% docs online %}
Whether the action is a online as opposed to IRL.
{% enddocs %}

{% docs post_online_offline %}
Aggregate. Whether the posts are online, offline (IRL), or both, e.g. ("Online", "Offline", "Online , Offline")
{% enddocs %}

{% docs time_commitment %}
Estimated time required to do the action (e.g. 3.0+, <0.5)
{% enddocs %}

{% docs num_signups %}
Quantity of campaign signups
{% enddocs %}

{% docs most_recent_signup %}
Timestamp of the most recent signup in UTC (eg. 2018-01-01 12:00:00)
{% enddocs %}

{% docs num_rbs %}
Quantity of reportbacks for the user
{% enddocs %}

{% docs total_quantity %}
Total quantity of items in reportbacks
{% enddocs %}

{% docs most_recent_rb %}
When the most recent reportback occurred in UTC (eg. 2018-01-01 12:00:00)
{% enddocs %}

{% docs first_rb %}
When the first reportback occurred in UTC (eg. 2018-01-01 12:00:00)
{% enddocs %}

{% docs avg_time_betw_rbs %}
Calculated average time between reportbacks.
{% enddocs %}

{% docs avg_days_next_action_after_rb %}
Calculated average days until next action after reportback
{% enddocs %}

{% docs days_to_next_action_after_last_rb %}
This is a unique identifier for each event
{% enddocs %}

{% docs most_recent_mam_action %}
Most recent monthly active member qualifying action in UTC (eg. 2018-01-01 12:00:00).
{% enddocs %}

{% docs most_recent_email_open %}
Most recent email open in UTC (eg. 2018-01-01 12:00:00)
{% enddocs %}

{% docs most_recent_all_actions %}
Most recent timestamp of any action in UTC (eg. 2018-01-01 12:00:00)
{% enddocs %}

{% docs last_action_is_rb %}
Whether the last action the user took was a reportback
{% enddocs %}

{% docs days_since_last_action %}
Days since the user's last action
{% enddocs %}

{% docs time_to_first_rb %}
How much time after registering until the user's first reportback
{% enddocs %}

{% docs sms_unsubscribed_at %}
Timestamp of when user unsubscribed from SMS messaging
{% enddocs %}

{% docs user_unsubscribed_at %}
Timestamp of when user unsubscribed from email or sms
{% enddocs %}

{% docs voter_reg_acquisition %}
Whether the user was an acquisition through voter registration efforts. 
{% enddocs %}

{% docs last_logged_in %}
Date time in UTC when user last logged in to Northstar
{% enddocs %}

{% docs last_accessed %}
Date time in UTC when user last access the website
{% enddocs %}

{% docs last_messaged_at %}
Date time in UTC when user was last sent a message via SMS or email
{% enddocs %}

{% docs facebook_id %}
User's facebook id
{% enddocs %}

{% docs mobile %}
Users's mobile phone number
{% enddocs %}

{% docs birthdate %}
User's birthdate
{% enddocs %}

{% docs first_name %}
User's first name
{% enddocs %}

{% docs last_name %}
User's last name
{% enddocs %}

{% docs voter_registration_status %}
User's registration status. (e.g. registration_complete, confirmed, uncertain) 
{% enddocs %}

{% docs finish_with_state %}
If the registrant was eligible to use and passed through to complete their registration with their state’s OVR system, it will be indicated in this field (direct quote from Rock-The-Vote documentation). Yes/No value in field.
{% enddocs %}

{% docs reportback_volume %}
This field returns 1 if non voter-reg action, since campaigns team only counts those a 1 reportback. If voter-reg action, we want to count quantity of post as number of registered voters.
{% enddocs %}

{% docs address_street_1 %}
First line of user's street address
{% enddocs %}

{% docs address_street_2 %}
Second line of user's street address
{% enddocs %}

{% docs city %}
User's city
{% enddocs %}

{% docs state %}
User's state
{% enddocs %}

{% docs country %}
User's country
{% enddocs %}

{% docs language %}
User's language
{% enddocs %}

{% docs cio_status %}
Status of user from CIO. (e.g. customer_subscribed, customer_unsubscribed)
{% enddocs %}

{% docs cio_status_timestamp %}
Timestamp when users's status was updated.
{% enddocs %}

{% docs sms_status %}
Current SMS status. (e.g. undeliverable, unknown)
{% enddocs %}

{% docs source_detail %}
Details of the origin of the user. (e.g. tell_a_friend, other, opt_in_path/197981)
{% enddocs %}

{% docs badges %}
Whether the user has any badges. 
{% enddocs %}

{% docs refer_friends %}
Whether the user is a part of the refer a friend campaign. 
{% enddocs %}

{% docs subscribed_member %}
Whether the user is subscribed. 
{% enddocs %}

{% docs last_updated_at %}
Timestamp when users's was updated.
{% enddocs %}

{% docs school_id %}
Unique identifier for the user's school. This info comes from the school finder.
{% enddocs %}

{% docs newsletter_topic %}
Newsletter topic. (e.g. community, lifestyle)
{% enddocs %}

{% docs user_agent %}
Full user agent string for a user's browser (e.g. "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:24.0) Gecko/20100101 Firefox/24.0")
{% enddocs %}

{% docs drupal_id %}
Old Drupal user ID
{% enddocs %}

{% docs campaigns %}
Campaigns a user is signed up for.
{% enddocs %}

{% docs audit %}
A very useful field with data containing information about changes to a user, e.g. timestamps when the user subscribed and unsubscribed.
{% enddocs %}

{% docs voting_plan_status %}
The indication of the user's plan to vote, e.g. voting, not_voting, cant_vote
{% enddocs %}

{% docs voting_plan_time_of_day %}
The time of day when the user plans to vote, e.g morning, afternoon, evening
{% enddocs %}

{% docs voting_plan_method_of_transport %}
How the user plans to get to their polling place. e.g. walk, drive
{% enddocs %}

{% docs voting_plan_attending_with %}
With Whom the user plans to go voting, e.g. family, friends, alone
{% enddocs %}

{% docs feature_flags %}
JSON containing info on features like badges and refer-a-friend.
{% enddocs %}

{% docs dbt_updated_at %}
DBT snapshot table data. The updated_at timestamp of the source record when this snapshot row was inserted.
{% enddocs %}

{% docs dbt_scd_id %}
DBT snapshot table data. A unique key generated for each snapshotted record.
{% enddocs %}

{% docs dbt_valid_from %}
DBT snapshot table data. The dbt_valid_from and dbt_valid_to columns indicate the historical state for a given record. The current value for a row is represented with a null value for dbt_valid_to. The timestamp when this snapshot row was first inserted
{% enddocs %}

{% docs dbt_valid_to %}
DBT snapshot table data. The dbt_valid_from and dbt_valid_to columns indicate the historical state for a given record. The current value for a row is represented with a null value for dbt_valid_to. The timestamp when this row row became invalidated.
{% enddocs %}

{% docs google_id %}
User's Google ID obtained from login.
{% enddocs %}

{% docs causes %}
Causes in which a user is interested. e.g. animal welfare, education, mental_health
{% enddocs %}

{% docs email_subscription_status %}
Email subscription status of the user
{% enddocs %}

{% docs role %}
User's role, e.g. user, staff
{% enddocs %}

{% docs cio_backfilled %}
Whether this user's data was backfilled from CIO
{% enddocs %}

{% docs addr_source %}
Where the user submitted their address, e.g. sms, GDPR
{% enddocs %}

{% docs email_subscription_topics %}
Email subscription topics correspond to categories in CIO in which the user is interested. e.g. lifestyle, community, scholarship
{% enddocs %}

{% docs sms_paused %}
Whether we've paused sending sms messages to the user.
{% enddocs %}

{% docs months_since_created %}
How many months since the user was created
{% enddocs %}

{% docs last_mam %}
Date corresponding to the most recent member action
{% enddocs %}

{% docs period_start %}
Date corresponding to the start of the period analyzing how newsletter subscription status contributes to campaign sign-up

Context: Period start and end are simply the start and end of the month. In a previous iteration of the model, some periods were 5-months long which is why these fields are not called months.
{% enddocs %}

{% docs period_end %}
Date corresponding to the end of the period analyzing how newsletter subscription status contributes to campaign sign-up

Context: Period start and end are simply the start and end of the month. In a previous iteration of the model, some periods were 5-months long which is why these fields are not called months.
{% enddocs %}

{% docs nl_status %}
Newsletter status, whether or not the user is subscribed to the newsletter
{% enddocs %}

{% docs signup_source %}
Source of signup, e.g. "sms" or "web"
{% enddocs %}

{% docs signup_source_bucket %}
Grouping bucket for origin of the signup, e.g. "sms", "web", "voter-reg" or "niche"
{% enddocs %}

{% docs signup_date %}
Date when user signed up for newsletter
{% enddocs %}

{% docs journey_begin_ts %}
The first time the user landed on this URL
{% enddocs %}

{% docs page_visit %}
Has the user visited the OVRD URL
{% enddocs %}

{% docs page_id %}
The distinct page_id for which the event occurred on. This is currently optional, but will eventually be required (TODO).
{% enddocs %}

{% docs click_join_us %}
Did the user click the Join Us button to sign up for the campaign. Phoenix Events Combined event_name = phoenix_clicked_signup
{% enddocs %}

{% docs authenticated %}
Did the user view the page while authenticated
{% enddocs %}

{% docs click_start_registration %}
Did the user click the Start Registration button to go to Instapage. Phoenix Events Combined event_name = phoenix_clicked_voter_registration_action
{% enddocs %}

{% docs clicked_get_started %}
Did the user start the registration process on Instapage.
{% enddocs %}

{% docs registered %}
Has the user registered to vote?
{% enddocs %}

{% docs click_copy_link %}
Did the user copy their unique link to share. Phoenix Events Combined event_name = phoenix_clicked_copy_to_clipboard
{% enddocs %}

{% docs clicked_any_share %}
Did the user click any of the social share buttons. Phoenix Events Combined event_name = 'phoenix_clicked_share_action_facebook','phoenix_clicked_share_email', 'phoenix_clicked_share_facebook_messenger','phoenix_clicked_share_twitter'
{% enddocs %}

{% docs clicked_share_fb %}
Did the user click the share via Facebook button? Phoenix Events Combined event_name = phoenix_clicked_share_action_facebook
{% enddocs %}

{% docs clicked_share_email %}
Did the user click the share via email button? Phoenix Events Combined event_name = phoenix_clicked_share_email
{% enddocs %}

{% docs clicked_share_fb_msgr %}
Did the user click the share via Facebook Messenger button? Phoenix Events Combined event_name = phoenix_clicked_share_facebook_messenger
{% enddocs %}

{% docs clicked_share_twitter %}
Did the user click the share via Twitter button? Phoenix Events Combined event_name = phoenix_clicked_share_twitter
{% enddocs %}

{% docs clicked_link %}

{% enddocs %}

{% docs completed_registration %}
Did the user complete their registration?
{% enddocs %}

{% docs traffic_source %}
Where did this user come from? Is it from one of our top partners or an internal product?
{% enddocs %}

{% docs submitted_quiz %}
Did the user submit the quiz?
{% enddocs %}

{% docs clicked_submit_photo %}
Did the user attempt to submit a photo post on the page?
{% enddocs %}

{% docs referrals_start %}
How many people did this user refer that started the registration process
{% enddocs %}

{% docs referrals_completed %}
How many people did this user refer that completed the registration process
{% enddocs %}

{% docs clicked_get_started_affirmation %}
Began the RTV registration flow via the Quiz Affirmation
{% enddocs %}

{% docs clicked_get_started_quiz_complete %}
Began the RTV registration flow via Quiz Completion
{% enddocs %}

{% docs registered_affirmation %}
Completed the RTV registration flow via Affirmation
{% enddocs %}

{% docs registered_quizcomplete %}
Completed the RTV registration flow via Quiz Completion
{% enddocs %}

{% docs register_affirmation_then_quiz %}
Registered via Affirmation, then returned to take the quiz
{% enddocs %}

{% docs latest_get_started_ts %}
The most recent time the user clicked Get Started on the RTV block
{% enddocs %}

{% docs latest_registered_ts %}
The most recent time the user registered to vote
{% enddocs %}

{% docs submit_quiz_register_affirmation %}
Submitted the quiz, and then registered to vote
{% enddocs %}

{% docs comparison_patterns %}
Pattern e.g. (Both are Unknown, One is Unknown, Same, Different)
{% enddocs %}

{% docs group_type_id %}
Group type id is....
{% enddocs %}

{% docs external_id %}
External id is....
{% enddocs %}

{% docs filter_by_state %}
Filter by state is....
{% enddocs %}

{% docs goal %}
The goal of the group
{% enddocs %}

{% docs group_name %}
The name of the group
{% enddocs %}
