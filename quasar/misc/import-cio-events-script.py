# -*- coding: utf-8 -*-
"""

About this script:
    - it is non-destructive. It doesn't import
    directly into a production table.
    - Uses SQL Alchemy as its ORM
    - Bulk imports events. The batch size is configurable. Defaults to 1000.
    - Imports into an import table with name pattern: import_table_[HASH]_[YYYYMMDD]
    - Import of the events into the actual production table is expected to
    be handled manually (SQL) by a data engineer.

Usage:
     $ pipenv run python import-cio-events-script.py \
        ~/Desktop/test-payloads.txt 500
"""

# import necessary libraries

import getpass
import json
import math
import os
import sys
import signal
import time
from colorama import init, Fore, Back
from datetime import datetime
from halo import Halo
from sqlalchemy import (create_engine, DDL, event, MetaData,
                        Table, Column, DateTime, String)
from sqlalchemy.engine import Engine
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.engine.url import URL
from zlib import adler32

# setup

init(autoreset=True)
spinner = Halo(spinner="circle")

batch_size = 1000
schema = "cio"
path_error_msg = "{}{}Please provide a valid path to the events file!!".format(
    Back.WHITE, Fore.RED)


pg_ssl = os.getenv('PG_SSL')
pg_opts = {
    'drivername': os.getenv('PG_DRIVER'),
    'username': os.getenv('PG_USER'),
    'password': os.getenv('PG_PASSWORD'),
    'host': os.getenv('PG_HOST'),
    'port': os.getenv('PG_PORT'),
    'database': os.getenv('PG_DATABASE')
}


# Validate user input


try:
    input_file = sys.argv[1]
except IndexError:
    spinner.fail(path_error_msg)
    exit(1)
try:
    batch_size = int(sys.argv[2])
except:
    # If batch_size parsing fails, just use the default
    pass

# Define util methods


def get_autovacuum_statement(toggle):
    table_name = get_import_table_name()
    command = 'true' if toggle else 'false'
    raw_statement = "ALTER TABLE {}.{} SET (autovacuum_enabled = {});".format(schema, table_name, command)
    return DDL(raw_statement)


def clean_exit(conn):
    conn.execute(get_autovacuum_statement(True))
    # TODO: Wait for autovacuum to finish running
    time.sleep(5)
    conn.close()


def get_application_name():
    return "{}_{}_{}".format(
        os.path.basename(__file__),
        get_username_hash(),
        get_today_string())


def get_today_string():
    return datetime.today().strftime('%Y%m%d')


def get_username_hash():
    return adler32(bytes(getpass.getuser().encode('utf-8')))


def get_import_table_name():
    # We are hashing and using the script executor's username as part
    # of the table name to prevent a collision with a parallel import
    return 'import_table_' + str(get_username_hash()) + '_' + get_today_string()


def get_file_path(given_path):
    cwd = os.path.abspath(os.path.dirname(__file__))
    return os.path.abspath(os.path.join(cwd, given_path))


def get_num_events(filePath):
    stream = os.popen("wc -l {} | pcregrep -oih '\w\d*(?=\s)'".format(
        filePath))
    return stream.read().rstrip()


def validate_file_path(filePath):
    if not os.path.exists(filePath):
        spinner.fail(path_error_msg)
        exit(1)


# Define event handlers


@event.listens_for(Engine, "handle_error")
def handle_error(exception_context):
    print('Handle Error: ', exception_context)


def signint_handler(sig, frame):
    spinner.warn("Script canceled by user input (Ctrl+C)")
    # TODO: Cleanly exit
    exit(0)


"""

It will record the Unix timestamp right before executing a query.
Useful to calculate how much time we have spent waiting for queries
to execute.
"""
@event.listens_for(Engine, "before_cursor_execute")
def before_cursor_execute(conn, cursor, statement,
                          parameters, context, executemany):
    conn.info.setdefault('query_start_time', []).append(time.time())


"""

The first step of the script is to create the table that we will import
the events into. This method is called when the table is created.
This ensures that we insert the events AFTER the table is available.
"""
@event.listens_for(Table, "after_create")
def on_table_created(target, conn, **kw):
    spinner.start()


    conn.execute(get_autovacuum_statement(False))


    spinner.info("{}{} is ready to start importing".format(
        Fore.LIGHTBLACK_EX, target))
    num_events = get_num_events(filePath)
    spinner.info("{}Started import of {} events in file {}{}".format(
        Fore.LIGHTBLACK_EX, num_events, Fore.CYAN, filePath))

    # Holds the events that will be inserted in the current batch
    buffer = []
    total_batches = math.ceil(int(num_events) / batch_size)
    current_batch = 1
    with open(filePath) as cio_events:
        for cio_event in cio_events:
            json_event = json.loads(cio_event)['data']
            buffer.append({
                "event": json_event,
                "event_id": json_event['event_id'],
                "timestamp": datetime.fromtimestamp(
                    json_event['timestamp']).isoformat()
            })
            # Insert events after we have reached the batch size
            if len(buffer) % batch_size == 0:
                spinner.start("{}Processing batch number {} of {}".format(
                    Fore.LIGHTBLACK_EX, current_batch, total_batches))
                db.execute(import_table.insert(), buffer)
                # reset the buffer
                buffer = []
                current_batch += 1
    # Imports the remainder events in the buffer
    if len(buffer) > 0:
        spinner.start("{}Processing batch number {} of {}".format(
            Fore.LIGHTBLACK_EX, current_batch, total_batches))
        db.execute(import_table.insert(), buffer)

    # Calculates total query execution time
    total_time = math.ceil(time.time() - conn.info['query_start_time'].pop(0))
    spinner.succeed("{}Finished. Total Time: {} sec".format(
        Fore.GREEN, total_time))
    clean_exit(conn)


signal.signal(signal.SIGINT, signint_handler)


filePath = get_file_path(input_file)


validate_file_path(filePath)


try:
    db = create_engine(
        URL(**pg_opts),
        connect_args={
            'sslmode': pg_ssl,
            'application_name': get_application_name()
            },
        pool_recycle=600
        # Uncomment for debug logs
        # ,echo=True
    )
    # Connect to DB
    conn = db.connect()
except:
    spinner.fail("Error establishing connection. Error: {}".format(
        sys.exc_info()))

meta = MetaData()

# create import table
import_table = Table(
    get_import_table_name(),
    meta,
    Column('event', JSONB),
    Column('timestamp',
           DateTime(timezone=True)),
    Column('event_id', String),
    schema=schema)

"""

The default is to drop the import table on every run.
It makes the outcome of the script predictable.
"""
import_table.drop(db, checkfirst=True)
# create
import_table.create(db)
