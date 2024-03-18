#! /usr/bin/python3

import os
import time
import requests
import logging
import argparse
import configparser
from pydal import DAL, Field
from datetime import datetime, timezone
from pprint import pprint

basedir = os.path.dirname(os.path.realpath(__file__))

try:
    config = configparser.ConfigParser()
    config.read(f"{basedir}/config.ini")

    graylog_api_url = config['graylog']['api_url']
    graylog_query_string = config['graylog']['query_string']
    graylog_query_source = config['graylog']['query_source']
    graylog_stream = config['graylog']['stream']
    graylog_api_token = config['graylog']['api_token']
    graylog_query_limit = config['graylog']['query_limit']
    loglevel = config['logging']['level']
    verbose = config.getboolean('logging', 'verbose')
    db_url = config['db']['url']
    db_commit = config.getboolean('db', 'commit')
except Exception as error:
    print(f"Could not read/parse config\n{ type(error).__name__ }: {error}")
    exit(255)

def epoch_to_iso8601(epoch_timestamp):
    dt_object = datetime.fromtimestamp(epoch_timestamp, timezone.utc)
    iso8601_string = dt_object.isoformat()

    return iso8601_string

def iso8601_to_epoch(iso8601_timestamp):
    dt_object = datetime.fromisoformat(iso8601_timestamp)
    epoch_time = dt_object.timestamp()

    return int(epoch_time)

def validate_iso8601(value):
    try:
        datetime.strptime(value, "%Y-%m-%dT%H:%M:%S")
        return value
    except ValueError:
        raise argparse.ArgumentTypeError(f"{value} is not a valid ISO 8601 date, please use: 'YYYY-MM-DDTHH:MM:SS'")

def validate_dburl(value):
    try:
        DAL(value)
        return value
    except:
        raise argparse.ArgumentTypeError(f"{value} is not a valid database URL or the dabase could not be accessed")

parser = argparse.ArgumentParser(
                    prog='get_newsletter_info.py',
                    description='Fetches infos from graylog API and store the result into a given database',
                    epilog='WARNING: Use "--start" with great care (and/or consider using "--no-commit"), otherwise you might end up with redundant entries in your database. Please also note that query results might be limited to 10000 entries (graylog default). You can change this by increasing "index.max_result_window", e.g.:  curl -H \'Content-Type: application/json\' -XPUT "http://localhost:9200/_settings" -d \'{"index": {"max_result_window": 50000}}\'')

exgroup = parser.add_mutually_exclusive_group()
exgroup.add_argument("-s", "--start", type=validate_iso8601, help="Graylog query start date as ISO 8601-formatted timestamp (default: last successful run)")
parser.add_argument("-t", "--token", default=graylog_api_token, help="Graylog API token (default: **REDACTED**)")
parser.add_argument("--source", default=graylog_query_source, help=f"Graylog query source (default: {graylog_query_source})")
parser.add_argument("--stream", default=graylog_stream, help=f"Graylog stream (default: {graylog_stream})")
parser.add_argument("--limit", default=graylog_query_limit, help=f"Graylog query limit (default: {graylog_query_limit})")
parser.add_argument("-q", "--query", default=graylog_query_string, help=f"Graylog query string (default: {graylog_query_string})")
parser.add_argument("-a", "--api", default=graylog_api_url, help=f"Graylog API URL (default: {graylog_api_url})")
parser.add_argument("-d", "--db", type=validate_dburl, default=db_url, help=f"Database URL (default: { db_url })")
parser.add_argument("-l", "--loglevel", default=loglevel, choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'], help=f"Set the loglevel (default: { loglevel })")
parser.add_argument("-v", "--verbose", default=verbose, action='store_true', help=f"Print graylog API result as JSON object and database results (default: { verbose })")
parser.add_argument("-c", "--commit", default=db_commit, action=argparse.BooleanOptionalAction, help=f"Commit query results to database?")
exgroup.add_argument("-p", "--prometheus", default=False, action='store_true', help=f"Write data to prometheus node exporter textfile collector (default: False)")
args = parser.parse_args()

logging.basicConfig(level=getattr(logging, args.loglevel), format='%(asctime)s %(levelname)s: %(message)s', datefmt='%d.%m.%Y %H:%M:%S')

db = DAL(uri=args.db,folder=basedir)
newsletter_logs = db.define_table('newsletter_logs', Field('timestamp', 'string'), Field('start', 'string'), Field('end', 'string'), Field('newsletter_id', 'string'), Field('count', 'string'))
newsletter_meta = db.define_table('newsletter_meta', Field('key', 'string'), Field('value', 'string'))

current_dateTime = int(time.time())
current_dateTime_ISO = epoch_to_iso8601(current_dateTime)

if not args.start:
    lastrun_query = db(newsletter_meta.key == 'lastrun').select(orderby=newsletter_meta.id)
    if lastrun_query:
        logging.info("Lastrun query was successful")
        lastrun = lastrun_query.last().value
        lastrun_ISO = epoch_to_iso8601(int(lastrun))
    else:
        logging.warning("Lastrun query was not successful, using '01.01.1970' as start date")
        lastrun_ISO = '1970-01-01T00:00:00.000Z'
        lastrun = 0
else:
    lastrun_ISO = args.start
    lastrun = iso8601_to_epoch(args.start)

logging.debug(f"graylog_query_start    : {lastrun_ISO}")
logging.debug(f"graylog_api_url        : {args.api}")
logging.debug(f"graylog_query_string   : {args.query}")
logging.debug(f"graylog_query_source   : {args.source}")
logging.debug(f"graylog_query_limit    : {args.limit}")
logging.debug(f"graylog_stream         : {args.stream}")
logging.debug(f"db                     : {args.db}")
logging.debug(f"db_commit              : {args.commit}")
logging.debug(f"loglevel               : {args.loglevel}")

payload = {
  "queries": [
    {
      "id": "?",
      "timerange": {
          "type": "absolute",
          "from": str(lastrun_ISO),
          "to": str(current_dateTime_ISO)
       },
      "query": {
        "type": "elasticsearch",
        "query_string": "message:\"GET "+str(args.query)+"\" AND source:"+str(args.source)+" AND status:200"
      },
      "search_types": [{
            "streams": [""+str(args.stream)+""],
            "id": "?",
            "type": "messages",
            "limit": int(args.limit)
          }]
    }
  ]
}

header = {
    'X-Requested-By':'Newsletter Info Query',
}

r = requests.post(args.api, auth=(args.token, 'token'), headers=header, timeout=10, json=payload)

if r.status_code != 200:
    logging.error('Error fetching data from graylog API')
    exit(2)

try:
    results = r.json()
except:
    logging.error('Could not parse JSON response from graylog API')
    exit(3)

if args.verbose:
    pprint(results)

if results['execution']['cancelled'] != False:
    logging.error('The graylog API query was cancelled')
    exit(3)
if results['execution']['completed_exceptionally'] != False:
    logging.warning('The graylog API query did not completed successfully')
if len(results['results']['?']['errors']) > 0:
    logging.error('The graylog API query generated errors')
    logging.error(results['errors'][0]['description'])
    exit(4)

logging.info(f"The graylog API query took: {results['results']['?']['execution_stats']['duration']}ms")
logging.info(f"The effective query timerange was from: {results['results']['?']['execution_stats']['effective_timerange']['from']} to: {results['results']['?']['execution_stats']['effective_timerange']['to']}")
logging.info(f"The graylog API query has {results['results']['?']['search_types']['?']['total_results']} results (messages)")

if results['results']['?']['search_types']['?']['total_results'] > int(args.limit):
    logging.warning(f"The query has more results than the query limit, only {args.limit} entries will be evaluated")

count = {}
for message in results['results']['?']['search_types']['?']['messages']:
    newsletter_id = message['message']['url']
    newsletter_id = newsletter_id.split('?')
    newsletter_id = newsletter_id[0]
    if newsletter_id not in count:
        count[newsletter_id] = 1
    else:
        count[newsletter_id] += 1

newsletter_count_total = results['results']['?']['search_types']['?']['total_results']
current_dateTime = int(time.time())

lastrun_db = db(newsletter_meta.key == 'lastrun').select()
if not lastrun_db:
    newsletter_meta.insert(key='lastrun',value=current_dateTime)
else:
    db(newsletter_meta.key == 'lastrun').update(key='lastrun', value=current_dateTime)

newsletter_meta.insert(key='total_newsletter_views_'+str(current_dateTime),value=newsletter_count_total)

i = 0
ti = 0
for key in count:
    timestamp = current_dateTime
    start = results['results']['?']['execution_stats']['effective_timerange']['from']
    end = results['results']['?']['execution_stats']['effective_timerange']['to']
    logging.debug(f"Found entry: timestamp={current_dateTime},start={start},end={end},newsletter_id={key},count={count[key]}")
    newsletter_logs.insert(timestamp=timestamp,start=start,end=end,newsletter_id=key,count=count[key])
    i += 1
    ti += count[key]

if args.commit:
    db.commit()
    logging.info(f"A total of {i} unique newsletter entries (out of {ti} processed views) have been written to database")
    logging.info(f"Lastrun date has been set to {current_dateTime_ISO} ({current_dateTime})")
else:
    logging.info(f"As requested: None of the {i} unique newsletter entries (out of {ti} processed views) have been written")
    logging.warning('Use "-c/--commit" to actually write results to the database')

if args.verbose:
    for row in db(newsletter_logs).select():
        print(row)

    for row in db(newsletter_meta).select():
        print(row)

if args.prometheus:
    logging.debug('Writing data to prometheus node exporter (textfile collector)')
    with open('/var/lib/prometheus/node-exporter/newsletter_stats.prom', 'w+') as f:
        for key in count:
            f.write(f"newsletter_stats{{item=\"{key}\"}} {count[key]}\n")
    f.close()
