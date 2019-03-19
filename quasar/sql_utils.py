import os
import pandas as pd
import sys
import time

from .database import Database
from .sa_database import Database as sadb
from sqlalchemy import create_engine
from .utils import log


class DataFrameDB:
    def __init__(self, opts={}):

        self.opts = {
            'user': os.environ.get('PG_USER'),
            'host': os.environ.get('PG_HOST'),
            'password': os.environ.get('PG_PASSWORD'),
            'db': os.environ.get('PG_DATABASE'),
            'port': str(os.environ.get('PG_PORT')),
            'use_unicode': True,
            'charset': 'utf8'
        }

        self.engine = create_engine(
            'postgresql+psycopg2://' +
            self.opts['user'] +
            ':' +
            self.opts['password'] +
            '@' +
            self.opts['host'] +
            ':' +
            self.opts['port'] +
            '/' +
            self.opts['db'])

    def run_query(self, query):
        if '.sql' in query:
            q = open(query, 'r').read()
        else:
            q = query
        try:
            pd.read_sql_query(q, self.engine)
        except Exception as e:
            success = ''.join(("This result object does not return rows. "
                               "It has been closed automatically."))

            if str(e) == success:
                print("From Team Storm Engineers:")
                print("The query ran successfully if you're reading this.")
                print("We'll make this more graceful in the future.")
                sys.exit(0)
            else:
                print("Query did not run successfully. Error is:")
                print(e)
                sys.exit(1)


def run_sql_file_old(file):
    df = DataFrameDB()
    df.run_query(file)


def sql_replace(query, datamap):
    """Used for find/replace variables in sql_run_file function based
    on a regular pattern.
    """
    # Remove any newlines.
    final_query = query.replace("\n", "")
    # Based on variables in datamap, replace ':' prepended values
    # with actual values.
    for key in datamap:
        j = ':' + key
        final_query = final_query.replace(j, datamap[key])
    return final_query


def run_sql_file(file, datamap):
    template = open(file, 'r').read()
    queries = template.split(";")
    db = sadb()
    for i in queries:
        i = sql_replace(i, datamap)
        # If query is empty, will throw an error.
        if i != "":
            log("Running query:")
            log(i)
            db.query(i)
    db.disconnect()


def refresh_materialized_view(view):
    db = Database()
    start_time = time.time()
    """Keep track of start time of script."""

    db.query("REFRESH MATERIALIZED VIEW " + view)
    db.disconnect()

    end_time = time.time()  # Record when script stopped running.
    duration = end_time - start_time  # Total duration in seconds.
    print('duration: ', duration)
