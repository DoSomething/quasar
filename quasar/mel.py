from .database_pg import Database
import time


def create():
    start_time = time.time()
    """Keep track of start time of script."""

    db = Database()
    db.query('DROP MATERIALIZED VIEW IF EXISTS public.member_event_log')
    db.query(''.join("CREATE MATERIALIZED VIEW public.member_event_log AS "
                     "(SELECT "
                     "MD5(concat(a.northstar_id, a.timestamp, a.action_id,"
                     " a.action_serial_id)) AS event_id,"
                     "a.northstar_id AS northstar_id,"
                     "a.timestamp AS timestamp,"
                     "a.action AS action_type,"
                     "a.action_id AS action_id,"
                     "a.source AS source,"
                     "a.action_serial_id AS action_serial_id "
                     "FROM ( "
                     "SELECT "
                     "DISTINCT s.northstar_id AS northstar_id,"
                     "s.created_at AS timestamp,"
                     "'signup' AS action,"
                     "'1' AS action_id,"
                     "s.source AS source,"
                     "s.id::varchar AS action_serial_id "
                     "FROM "
                     "("
                     "SELECT "
                     "sd.northstar_id,"
                     "sd.created_at,"
                     "sd.id,"
                     "sd.SOURCE,"
                     "sd.deleted_at "
                     "FROM "
                     "(SELECT "
                     "stemp.id,"
                     "max(stemp.updated_at) AS updated_at "
                     "FROM rogue.signups stemp "
                     "GROUP BY stemp.id) "
                     "s_maxupt "
                     "INNER JOIN rogue.signups sd "
                     "ON sd.id = s_maxupt.id AND sd.updated_at = "
                     "s_maxupt.updated_at"
                     ") s "
                     "WHERE s.deleted_at IS NULL "
                     "UNION ALL "
                     "SELECT "
                     "DISTINCT p.northstar_id AS northstar_id,"
                     "p.created_at AS timestamp,"
                     "'post' AS action,"
                     "'2' AS action_id,"
                     "p.source AS source,"
                     "p.id::varchar AS action_serial_id "
                     "FROM "
                     "("
                     "SELECT "
                     "pd.northstar_id,"
                     "pd.created_at,"
                     "pd.id,"
                     "pd.SOURCE,"
                     "pd.deleted_at "
                     "FROM "
                     "(SELECT "
                     "ptemp.id,"
                     "max(ptemp.updated_at) AS updated_at "
                     "FROM rogue.posts ptemp "
                     "GROUP BY ptemp.id) p_maxupt "
                     "INNER JOIN rogue.posts pd "
                     "ON pd.id = p_maxupt.id AND pd.updated_at = "
                     " p_maxupt.updated_at) p "
                     "WHERE p.deleted_at IS NULL "
                     "UNION ALL "
                     "SELECT "
                     "DISTINCT u.id AS northstar_id,"
                     "u.last_accessed_at AS timestamp,"
                     "'site_access' AS action,"
                     "'3' AS action_id,"
                     "NULL AS source,"
                     "'0' AS action_serial_id "
                     "FROM "
                     "northstar.users u "
                     "UNION ALL "
                     "SELECT "
                     "DISTINCT u.id AS northstar_id,"
                     "u.last_authenticated_at AS timestamp,"
                     "'site_login' AS action,"
                     "'4' AS action_id,"
                     "NULL AS source,"
                     "'0' AS action_serial_id "
                     "FROM "
                     "northstar.users u "
                     "UNION ALL "
                     "SELECT "
                     "DISTINCT u.id AS northstar_id,"
                     "u.created_at AS timestamp,"
                     "'account_creation' AS action,"
                     "'5' AS action_id,"
                     "u.source AS source,"
                     "'0' AS action_serial_id "
                     "FROM "
                     "northstar.users u "
                     "UNION ALL "
                     "SELECT "
                     "DISTINCT u.id AS northstar_id,"
                     "u.last_messaged_at AS timestamp,"
                     "'messaged_gambit' AS action,"
                     "'6' AS action_id,"
                     "'SMS' AS source,"
                     "'0' AS action_serial_id "
                     "FROM "
                     "northstar.users u "
                     "UNION ALL "
                     "SELECT "
                     "DISTINCT cio.customer_id AS northstar_id,"
                     "cio.timestamp AS timestamp,"
                     "'clicked_link' AS action,"
                     "'7' AS action_id,"
                     "cio.template_id::CHARACTER AS source,"
                     "cio.event_id AS action_serial_id "
                     "FROM "
                     "cio.email_event cio "
                     "WHERE "
                     "cio.event_type = 'email_clicked' "
                     "UNION ALL "
                     "SELECT "
                     "DISTINCT tv.nsid AS northstar_id,"
                     "tv.created_at AS timestamp,"
                     "'registered' AS action,"
                     "'8' AS action_id,"
                     "tv.source_details AS source,"
                     "tv.id as action_serial_id "
                     "FROM "
                     "public.turbovote_file tv "
                     "WHERE "
                     "tv.ds_vr_status IN ('register-form', "
                     "'confirmed', 'register-OVR') "
                     "AND "
                     "tv.nsid IS NOT NULL AND tv.nsid <> '' "
                     "UNION ALL "
                     "SELECT "
                     "DISTINCT pe.northstarid_s AS northstar_id,"
                     "to_timestamp(pe.ts /1000) AS timestamp,"
                     "'facebook share completed' AS action,"
                     "'9' AS action_id,"
                     "pe.event_source AS source,"
                     "pe.event_id AS action_serial_id "
                     "FROM "
                     "public.phoenix_next_events pe "
                     "WHERE "
                     "pe.event_name IN ('share action completed', "
                     "'facebook share posted') "
                     "AND pe.northstarid_s IS NOT NULL "
                     "AND pe.northstarid_s <> '' "
                     ") AS a "
                     ")"))
    db.query(''.join(("CREATE INDEX ON public.member_event_log "
                      "(event_id, northstar_id)")))
    db.query('GRANT SELECT ON public.member_event_log TO looker')
    db.query('GRANT SELECT ON public.member_event_log TO jjensen')
    db.query('GRANT SELECT ON public.member_event_log TO jli')
    db.query('GRANT SELECT ON public.member_event_log TO shasan')
    db.disconnect()

    end_time = time.time()  # Record when script stopped running.
    duration = end_time - start_time  # Total duration in seconds.
    print('duration: ', duration)


def main():
    start_time = time.time()
    """Keep track of start time of script."""

    db = Database()

    db.query('REFRESH MATERIALIZED VIEW public.member_event_log')
    db.disconnect()

    end_time = time.time()  # Record when script stopped running.
    duration = end_time - start_time  # Total duration in seconds.
    print('duration: ', duration)


if __name__ == "__create__":
    create()

if __name__ == "__main__":
    main()
