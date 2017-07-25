from datetime import datetime as dt
import logging
import sys
import time

from .config import config
from .utils import strip_str
from .DSMySQL import BladeMySQL
from .API import API

log_format = "%(asctime)s - %(levelname)s: %(message)s"
logging.basicConfig(level=logging.INFO, format=log_format)
campaign_activity_table = config.CAMPAIGN_ACTIVITY_TABLE


def full_backfill():
    """Processes Rogue data starting from last processed page recorded in 
    ROGUE_PROGRESS_TABLE; to restart from beginning, page_progress has to
    manually be set to 1.
    """
    _backfill()

def backfill_since():
    _backfill(hours=sys.argv[1])


def _backfill(hours=None):

    # Setup
    db = BladeMySQL()
    start_time = strip_str(_now_minus_hours(hours))  # empty string if None
    rogueAPI = API(''.join((config.ROGUE_URI, '/api/v2/activity')),
                   headers={'X-DS-Rogue-API-Key': config.DS_ROGUE_API_KEY},
                   params={'page': 1, 'limit': 40, 'filter[updated_at]': start_time})
    final_page = rogueAPI.get('')['meta']['pagination']['total_pages']

    if hours is not None:
        print("Current backfill hours are %s." % hours)
        current_page = 1
    else:
        current_page = _get_start_page(db)

    # Main processing loop
    while current_page <= final_page:
        print("Current page: %s of %s" % (current_page, final_page))
        data = rogueAPI.get('', params={'page': current_page})['data']
        _process_records(db, data)
        current_page += 1
        if hours is None:
            _update_progress(db, current_page)

    # Cleanup
    try:
        db.create_disconnect()
    except Exception as e:
        print("Exception is %s" % e)
        sys.exit(0)


def _get_start_page(db):
    querystr = ''.join(("SELECT counter_value FROM ", config.ROGUE_PROGRESS_TABLE,
                        " WHERE counter_name = 'rogue_backfill_page'"))

    last_page = strip_str(db.query(querystr))
    if last_page == '' or int(last_page) <= 1:
        return 1
    else:
        return int(last_page)


def _now_minus_hours(hours):
    """Returns time x hours ago"""
    if hours is None:
        return None
    else:
        start_time = int(time.time()) - (int(hours) * 3600)
        return dt.fromtimestamp(start_time).isoformat()


def _update_progress(db, page):
    db.query_str("REPLACE INTO " + config.ROGUE_PROGRESS_TABLE +
                 " (counter_name, counter_value) VALUES(%s, %s)",
                 ('rogue_backfill_page', page))


def _process_records(db, rogue_page):
    """Iterate over page of results and load into Blade DB."""
    for i in rogue_page:
        if i['posts']['data'] == []:
            db.query_str("REPLACE INTO " +
                         campaign_activity_table +
                         " SET northstar_id = %s,\
                              signup_id = %s,\
                              campaign_id = %s,\
                              campaign_run_id = %s,\
                              quantity = %s,\
                              why_participated = %s,\
                              signup_source = %s,\
                              signup_created_at = %s,\
                              signup_updated_at = %s,\
                              post_id = NULL,\
                              url = NULL,\
                              caption = NULL,\
                              status = NULL,\
                              remote_addr = NULL,\
                              post_source = NULL,\
                              submission_created_at = ''",
                         (strip_str(i['northstar_id']),
                          strip_str(i['signup_id']),
                          strip_str(i['campaign_id']),
                          strip_str(i['campaign_run_id']),
                          strip_str(i['quantity']),
                          strip_str(i['why_participated']),
                          strip_str(i['signup_source']),
                          strip_str(i['created_at']),
                          strip_str(i['updated_at'])))
        else:
            for j in i['posts']['data']:
                db.query_str("REPLACE INTO " +
                             campaign_activity_table +
                             " SET northstar_id = %s,\
                                  signup_id = %s,\
                                  campaign_id = %s,\
                                  campaign_run_id = %s,\
                                  quantity = %s,\
                                  why_participated = %s,\
                                  signup_source = %s,\
                                  signup_created_at = %s,\
                                  signup_updated_at = %s,\
                                  post_id = %s,\
                                  url = %s,\
                                  caption = %s,\
                                  status = %s,\
                                  remote_addr = %s,\
                                  post_source = %s,\
                                  submission_created_at = %s,\
                                  submission_updated_at = %s",
                             (strip_str(i['northstar_id']),
                              strip_str(i['signup_id']),
                              strip_str(i['campaign_id']),
                              strip_str(i['campaign_run_id']),
                              strip_str(i['quantity']),
                              strip_str(i['why_participated']),
                              strip_str(i['signup_source']),
                              strip_str(i['created_at']),
                              strip_str(i['updated_at']),
                              strip_str(j['id']),
                              strip_str(j['media']['url']),
                              strip_str(j['media']['caption']),
                              strip_str(j['status']),
                              strip_str(j['remote_addr']),
                              strip_str(j['source']),
                              strip_str(j['created_at']),
                              strip_str(j['updated_at'])))
