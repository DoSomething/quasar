from .database import Database
from .sql_utils import run_sql_file
import time


def create():
    start_time = time.time()
    """Keep track of start time of script."""

    run_sql_file('./data/sql/derived-tables/campaign_info.sql')
    end_time = time.time()  # Record when script stopped running.
    duration = end_time - start_time  # Total duration in seconds.
    print('duration: ', duration)


def main():
    start_time = time.time()
    """Keep track of start time of script."""

    db = Database()

    db.query('REFRESH MATERIALIZED VIEW rogue.campaign_info_all')
    db.query('REFRESH MATERIALIZED VIEW public.campaign_info')
    db.query('REFRESH MATERIALIZED VIEW public.campaign_info_international')
    db.disconnect()

    end_time = time.time()  # Record when script stopped running.
    duration = end_time - start_time  # Total duration in seconds.
    print('duration: ', duration)


if __name__ == "__create__":
    create()

if __name__ == "__main__":
    main()
