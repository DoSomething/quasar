import os

from .sa_database import Database
from .sql_utils import run_sql_file
from .utils import Duration


data = {
    'campaign_info_all': os.getenv('CAMPAIGN_INFO_ALL'),
    'field_data_field_campaigns': os.getenv('FIELD_DATA_FIELD_CAMPAIGNS'),
    'node': os.getenv('NODE'),
    'field_data_field_campaign_type': os.getenv(''.join(('FIELD_DATA_FIELD_'
                                                         'CAMPAIGN_TYPE'))),
    'field_data_field_run_date': os.getenv('FIELD_DATA_FIELD_RUN_DATE'),
    'field_data_field_call_to_action': os.getenv(''.join(('FIELD_DATA_FIELD_'
                                                          'CALL_TO_ACTION'))),
    'field_data_field_reportback_noun': os.getenv(''.join(('FIELD_DATA_FIELD_'
                                                           'REPORTBACK_'
                                                           'NOUN'))),
    'field_data_field_reportback_verb': os.getenv(''.join(('FIELD_DATA_FIELD_'
                                                           'REPORTBACK_'
                                                           'VERB'))),
    'field_data_field_action_type': os.getenv('FIELD_DATA_FIELD_ACTION_TYPE'),
    'taxonomy_term_data': os.getenv('TAXONOMY_TERM_DATA'),
    'field_data_field_cause': os.getenv('FIELD_DATA_FIELD_CAUSE'),
    'campaign_info': os.getenv('CAMPAIGN_INFO'),
    'campaigns': os.getenv('CAMPAIGNS'),
    'campaign_info_international': os.getenv('CAMPAIGN_INFO_INTERNATIONAL')
}


def create():
    """(Re)create materialized views: campaign_info_all, campaign_info,
    campaign_info_international.
    """
    duration = Duration()
    run_sql_file('./data/sql/derived-tables/campaign_info.sql', data)
    duration.duration()


def refresh():
    start_time = time.time()

    db = Database()
    duration = Duration()

    # Setting statement for schema diffs of campaign_info_all
    campaign_all = "REFRESH MATERIALIZED VIEW " + data['campaign_info_all']
    db.query(campaign_all)
    db.query('REFRESH MATERIALIZED VIEW public.campaign_info')
    db.query('REFRESH MATERIALIZED VIEW public.campaign_info_international')
    db.disconnect()
    duration.duration()


if __name__ == "__create__":
    create()

if __name__ == "__refresh__":
    refresh()
