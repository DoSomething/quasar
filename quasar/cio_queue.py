import json
import os
import pydash
import sys

from .sa_database import Database
from .queue import QuasarQueue
from .utils import log, logerr


class CioQueue(QuasarQueue):

    def __init__(self):
        self.amqp_uri = os.environ.get('AMQP_URI')
        self.blink_queue = os.environ.get('BLINK_QUEUE')
        self.blink_exchange = os.environ.get('BLINK_EXCHANGE')
        super().__init__(self.amqp_uri, self.blink_queue,
                         self.blink_exchange)
        self.db = Database()

    # Save entire c.io JSON blob to event_log table.
    def _log_event(self, data):
        record = {'event': json.dumps(data)}
        self.db.query_str(''.join(("INSERT INTO cio.event_log "
                                   "(event) VALUES :event")), record)
        log(''.join(("Logged data from "
                     "C.IO event id {}.")).format(data['event_id']))

    # Save customer sub data and dates.
    def _add_sub_event(self, data):
        record = {
            'email_id': data['data']['email_id'],
            'customer_id': data['data']['customer_id'],
            'email_address': data['data']['email_address'],
            'event_id': data['event_id'],
            'timestamp': data['timestamp'],
            'event_type': data['event_type']
        }
        self.db.query_str(''.join(("INSERT INTO cio.customer_event "
                                   "(email_id, customer_id, email_address, "
                                   "event_id, timestamp, "
                                   "event_type) VALUES (:email_id,"
                                   ":customer_id,:email_address,:event_id,"
                                   "to_timestamp(:timestamp),:event_type) "
                                   "ON CONFLICT (email_id, customer_id, "
                                   "timestamp, event_type) "
                                   "DO NOTHING")), record)
        return data['event_id']

    # Save customer unsub data and dates.
    def _add_unsub_event(self, data):
        if pydash.get(data, 'template_id'):
            record = {
                'email_id': data['data']['email_id'],
                'customer_id': data['data']['customer_id'],
                'email_address': data['data']['email_address'],
                'template_id': data['data']['template_id'],
                'event_id': data['event_id'],
                'timestamp': data['timestamp'],
                'event_type': data['event_type']
            }
            self.db.query_str(''.join(("INSERT INTO cio.customer_event "
                                       "(email_id, customer_id,"
                                       "email_address, template_id, event_id,"
                                       "timestamp, event_type) "
                                       "VALUES (:email_id,:customer_id,"
                                       ":email_address,:template_id,:event_id,"
                                       "to_timestamp(:timestamp),:event_type) "
                                       "ON CONFLICT (email_id, customer_id, "
                                       "timestamp, event_type) "
                                       "DO NOTHING")), record)
        else:
            record = {
                'email_id': data['data']['email_id'],
                'customer_id': data['data']['customer_id'],
                'email_address': data['data']['email_address'],
                'event_id': data['event_id'],
                'timestamp': data['timestamp'],
                'event_type': data['event_type']
            }
            self.db.query_str(''.join(("INSERT INTO cio.customer_event "
                                       "(email_id, customer_id,"
                                       "email_address, event_id, "
                                       "timestamp, event_type) "
                                       "VALUES (:email_id,:customer_id,"
                                       ":email_address,:event_id,"
                                       "to_timestamp(:timestamp),:event_type) "
                                       "ON CONFLICT (email_id, customer_id, "
                                       "timestamp, event_type) "
                                       "DO NOTHING")), record)
        log(''.join(("Added customer event from "
                     "C.IO event id {}.")).format(data['event_id']))

    # Save email event data and dates, e.g. email_click.
    def _add_email_event(self, data):
        record = {
            'email_id': data['data']['email_id'],
            'customer_id': data['data']['customer_id'],
            'email_address': data['data']['email_address'],
            'template_id': data['data']['template_id'],
            'event_id': data['event_id'],
            'timestamp': data['timestamp'],
            'event_type': data['event_type']
        }
        self.db.query_str(''.join(("INSERT INTO cio.email_event "
                                   "(email_id, customer_id, email_address, "
                                   "template_id, event_id, timestamp, "
                                   "event_type) VALUES "
                                   "(:email_id,:customer_id,:email_address,"
                                   ":template_id,:event_id,"
                                   "to_timestamp(:timestamp),:event_type) "
                                   "ON CONFLICT (email_id, customer_id, "
                                   "timestamp, event_type) "
                                   "DO NOTHING")), record)
        log(''.join(("Added email event from "
                     "C.IO event id {}.")).format(data['event_id']))

    # Save email sent event.
    def _add_email_sent_event(self, data):
        record = {
            'email_id': data['data']['email_id'],
            'customer_id': data['data']['customer_id'],
            'email_address': data['data']['email_address'],
            'template_id': data['data']['template_id'],
            'subject': data['data']['subject'],
            'event_id': data['event_id'],
            'timestamp': data['timestamp']
        }
        self.db.query_str(''.join(("INSERT INTO cio.email_sent "
                                   "(email_id, customer_id, email_address, "
                                   "template_id, subject, event_id, "
                                   "timestamp) VALUES "
                                   "(:email_id,:customer_id,:email_address,"
                                   ":template_id,:subject,:event_id,"
                                   "to_timestamp(:timestamp)) "
                                   "ON CONFLICT (email_id, customer_id, "
                                   "timestamp) DO NOTHING")), record)
        log(''.join(("Added email event from "
                     "C.IO event id {}.")).format(data['event_id']))

    # Save email event data and dates, e.g. email_click.
    def _add_email_click_event(self, data):
        record = {
            'email_id': data['data']['email_id'],
            'customer_id': data['data']['customer_id'],
            'email_address': data['data']['email_address'],
            'template_id': data['data']['template_id'],
            'subject': data['data']['subject'],
            'href': data['data']['href'],
            'link_id': data['data']['link_id'],
            'event_id': data['event_id'],
            'timestamp': data['timestamp'],
            'event_type': data['event_type']
        }
        self.db.query_str(''.join(("INSERT INTO cio.email_event "
                                   "(email_id, customer_id, email_address, "
                                   "template_id, subject, href, link_id, "
                                   "event_id, timestamp, "
                                   "event_type) VALUES "
                                   "(:email_id,:customer_id,:email_address,"
                                   ":template_id,:subject,:href,:link_id,"
                                   ":event_id,to_timestamp(:timestamp),"
                                   ":event_type) ON CONFLICT (email_id, "
                                   "customer_id, timestamp, event_type) "
                                   "DO NOTHING")), record)
        log(''.join(("Added email event from "
                     "C.IO event id {}.")).format(data['event_id']))

        # Save email bounced event.
    def _add_email_bounced_event(self, data):
        record = {
            'email_id': data['data']['email_id'],
            'customer_id': data['data']['customer_id'],
            'email_address': data['data']['email_address'],
            'template_id': data['data']['template_id'],
            'subject': data['data']['subject'],
            'event_id': data['event_id'],
            'timestamp': data['timestamp']
        }
        self.db.query_str(''.join(("INSERT INTO cio.email_bounced "
                                   "(email_id, customer_id, email_address, "
                                   "template_id, subject, event_id, "
                                   "timestamp) VALUES "
                                   "(:email_id,:customer_id,:email_address,"
                                   ":template_id,:subject,:event_id,"
                                   "to_timestamp(:timestamp)) "
                                   "ON CONFLICT (email_id, customer_id, "
                                   "timestamp) DO NOTHING")), record)
        log(''.join(("Added email bounced event from "
                     "C.IO event id {}.")).format(data['event_id']))

    def process_message(self, message_data):
        if pydash.get(message_data, 'data.meta.message_source') == 'rogue':
            message_id = pydash.get(message_data, 'data.data.id')
            log("Ack'ing Rogue message id {}".format(message_id))
        else:
            data = message_data['data']
            event_type = pydash.get(data, 'event_type')
            # Set for checking email event types.
            email_event = {
                'email_bounced',
                'email_converted',
                'email_opened',
                'email_unsubscribed'
            }
            # Always capture atomic c.io event in raw format.
            self._log_event(data)
            try:
                if event_type == 'customer_subscribed':
                    self._add_sub_event(data)
                elif event_type == 'customer_unsubscribed':
                    self._add_unsub_event(data)
                elif event_type == 'email_clicked':
                    self._add_email_click_event(data)
                elif event_type == 'email_sent':
                    self._add_email_sent_event(data)
                elif event_type == 'email_bounced':
                    self._add_email_bounced_event(data)
                elif event_type in email_event:
                    self._add_email_event(data)
                else:
                    pass
            except KeyError as e:
                logerr("C.IO message missing {}".format(e))
            except:
                logerr("Something went wrong with C.IO consumer!")
                sys.exit(1)
