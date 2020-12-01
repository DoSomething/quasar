UPDATE :customer_event
	SET email_address = NULL,
		event_id = NULL
	WHERE customer_id IN (SELECT _id FROM :users.northstar_users_snapshot WHERE deleted_at IS NOT NULL);

UPDATE :email_events
	SET email_address = NULL,
		event_id = NULL,
		subject = NULL,
		href = NULL,
		link_id = NULL
	WHERE customer_id IN (SELECT _id FROM :users.northstar_users_snapshot WHERE deleted_at IS NOT NULL);

DELETE FROM :event_log
	WHERE "event"#>>'{data,variables,customer,id}' IN (SELECT _id FROM :users.northstar_users_snapshot WHERE deleted_at IS NOT NULL);
