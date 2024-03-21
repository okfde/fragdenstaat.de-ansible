#! /usr/bin/python3

# pylint: disable=import-error
# pylint: disable=invalid-name
# pylint: disable=broad-exception-caught
# pylint: disable=raise-missing-from
# pylint: disable=consider-using-dict-items
# pylint: disable=missing-module-docstring
# pylint: disable=missing-function-docstring
# pylint: disable=line-too-long

import os
import time
import hashlib
import logging
import argparse
import configparser
from pprint import pprint
from datetime import datetime, timezone, timedelta

import requests
from pydal import DAL, Field

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
    dt_object = datetime.fromisoformat(iso8601_timestamp.replace('.000Z',''))
    epoch_time = dt_object.timestamp()

    return int(epoch_time)

def validate_iso8601(value):
    try:
        datetime.strptime(value, "%Y-%m-%dT%H:%M:%S")
        return value
    except ValueError:
        raise argparse.ArgumentTypeError(f"{value} is not a valid ISO 8601 date, please use: 'YYYY-MM-DDTHH:MM:SS'")

def convert_input_date(isodate):
    converted_date = {}
    isodate = isodate.split(':')[0]
    isodate = isodate.split('-')
    day_hour = isodate[2].split('T')

    converted_date = { "year": int(isodate[0]),
                       "month": int(isodate[1]),
                       "day": int(day_hour[0]),
                       "hour": int(day_hour[1]),
                       "minute": 0 }

    return converted_date

def check_future_date(dtd):
    if dtd > datetime.now():
        print("future dates are not possible")
        exit(254)

    return False

def validate_dburl(value):
    try:
        DAL(value)
        return value
    except:
        raise argparse.ArgumentTypeError(f"{value} is not a valid database URL or the dabase could not be accessed")

parser = argparse.ArgumentParser(
                    prog='get_newsletter_info.py',
                    description='Fetches infos from graylog API and store the result into a given database',
                    epilog='Please note that query results might be limited to 10000 entries (graylog default). You can change this by increasing "index.max_result_window", e.g.:  curl -H \'Content-Type: application/json\' -XPUT "http://localhost:9200/_settings" -d \'{"index": {"max_result_window": 50000}}\'')

parser.add_argument("-s", "--start", type=validate_iso8601, help="Graylog query start date as ISO 8601-formatted timestamp (default: last successful run)")
parser.add_argument("-t", "--token", default=graylog_api_token, help="Graylog API token (default: **REDACTED**)")
parser.add_argument("--source", default=graylog_query_source, help=f"Graylog query source (default: {graylog_query_source})")
parser.add_argument("--stream", default=graylog_stream, help=f"Graylog stream (default: {graylog_stream})")
parser.add_argument("--limit", default=graylog_query_limit, help=f"Graylog query limit (default: {graylog_query_limit})")
parser.add_argument("-q", "--query", default=graylog_query_string, help=f"Graylog query string (default: {graylog_query_string})")
parser.add_argument("-a", "--api", default=graylog_api_url, help=f"Graylog API URL (default: {graylog_api_url})")
parser.add_argument("-d", "--db", type=validate_dburl, default=db_url, help=f"Database URL (default: { db_url })")
parser.add_argument("-l", "--loglevel", default=loglevel, choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'], help=f"Set the loglevel (default: { loglevel })")
parser.add_argument("-v", "--verbose", default=verbose, action='store_true', help=f"Print graylog API result as JSON object and database results (default: { verbose })")
parser.add_argument("-c", "--commit", default=db_commit, action='store_true', help=f"Commit query results to database (default: {db_commit})")
args = parser.parse_args()

logging.basicConfig(level=getattr(logging, args.loglevel), format='%(asctime)s %(levelname)s: %(message)s', datefmt='%d.%m.%Y %H:%M:%S')

db = DAL(uri=args.db,folder=basedir)
newsletter_logs = db.define_table(
    'newsletter_logs',
    Field('hash', type='string', unique=True),
    Field('start', type='string'),
    Field('end', type='string'),
    Field('newsletter_id', type='string'),
    Field('count', type='string')
)
newsletter_meta = db.define_table(
    'newsletter_meta',
    Field('key', type='string'),
    Field('value', type='string')
)
db.commit()

if not args.start:
    lastrun_query = db(newsletter_meta.key == 'lastrun').select(orderby=newsletter_meta.id)
    if lastrun_query:
        logging.debug("Lastrun query was successful")
        lastrun = lastrun_query.last().value
        lastrun_ISO = epoch_to_iso8601(int(lastrun))
    else:
        logging.error('Lastrun query was not successful, please specify a ISO-8601 formatted start date using "--start"')
        exit(253)
else:
    lastrun_ISO = args.start
    lastrun = iso8601_to_epoch(args.start)

current_dateTime = int(time.time())
current_dateTime_ISO = epoch_to_iso8601(current_dateTime)

startdate = convert_input_date(lastrun_ISO)
enddate = convert_input_date(current_dateTime_ISO)
startdate = datetime(
    startdate['year'],
    startdate['month'],
    startdate['day'],
    startdate['hour'],
    startdate['minute']
)
enddate = datetime(
    enddate['year'],
    enddate['month'],
    enddate['day'],
    enddate['hour'],
    enddate['minute']
)

check_future_date(startdate)
check_future_date(enddate)

logging.debug("lastrun                : %s", lastrun_ISO)
logging.debug("graylog_query_start    : %s", startdate)
logging.debug("graylog_query_end      : %s", enddate)
logging.debug("graylog_api_url        : %s", args.api)
logging.debug("graylog_query_string   : %s", args.query)
logging.debug("graylog_query_source   : %s", args.source)
logging.debug("graylog_query_limit    : %s", args.limit)
logging.debug("graylog_stream         : %s", args.stream)
logging.debug("db                     : %s", args.db)
logging.debug("db_commit              : %s", args.commit)
logging.debug("loglevel               : %s", args.loglevel)

header = {
    'X-Requested-By':'Newsletter Info Query',
}

difference = enddate - startdate
hours = int(difference.total_seconds() / 3600)

if hours <= 0:
    logging.error('Lastrun/Startdate was less than one hour ago, please try again later or adjust "--start".')
    exit(250)

logging.info("Lastrun/Startdate was %s hours ago, will make a graylog query for each hour", hours)
for t in range(1,hours + 1):
    currentStart = datetime.isoformat(startdate + timedelta(hours=t - 1))
    currentEnd = datetime.isoformat(startdate + timedelta(hours=t))

    payload = {
    "queries": [
        {
        "id": "?",
        "timerange": {
            "type": "absolute",
            "from": str(currentStart),
            "to": str(currentEnd)
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

    r = requests.post(args.api, auth=(args.token, 'token'), headers=header, timeout=10, json=payload)

    if r.status_code != 200:
        logging.error('Error fetching data from graylog API')
        exit(2)

    try:
        results = r.json()
    except Exception as err:
        logging.error("Could not parse JSON response from graylog API: %s", err)
        exit(3)

    if args.verbose:
        pprint(results)

    if results['execution']['cancelled'] is not False:
        logging.error('The graylog API query was cancelled')
        exit(3)
    if results['execution']['completed_exceptionally'] is not False:
        logging.warning('The graylog API query did not completed successfully')
    if len(results['results']['?']['errors']) > 0:
        logging.error('The graylog API query generated errors')
        logging.error(results['errors'][0]['description'])
        exit(4)

    logging.info("The graylog API query took: %sms",
                 results['results']['?']['execution_stats']['duration'])
    logging.info("The effective query timerange was from: %s to: %s",
                 results['results']['?']['execution_stats']['effective_timerange']['from'],
                 results['results']['?']['execution_stats']['effective_timerange']['to'])
    logging.info("The graylog API query has %s results (messages)",
                 results['results']['?']['search_types']['?']['total_results'])

    if results['results']['?']['search_types']['?']['total_results'] > int(args.limit):
        logging.warning(
            "The query has more results than the query limit, only %s entries will be evaluated",
            args.limit
        )

    count = {}
    for message in results['results']['?']['search_types']['?']['messages']:
        newsletter_id = message['message']['url']
        newsletter_id = newsletter_id.split('?')
        newsletter_id = newsletter_id[0]
        if newsletter_id not in count:
            count[newsletter_id] = 1
        else:
            count[newsletter_id] += 1

    if len(count) == 0:
        logging.warning("No results for timeframe, skipping...")
        continue

    i = 0
    ti = 0
    for key in count:
        start = results['results']['?']['execution_stats']['effective_timerange']['from']
        end = results['results']['?']['execution_stats']['effective_timerange']['to']
        md5sum = hashlib.md5(f"{start}{end}{key}{count[key]}".encode('utf-8')).hexdigest()
        logging.info("Found entry: start=%s,end=%s,newsletter_id=%s,count=%s", start, end, key, count[key])

        check_entry_query = newsletter_logs.hash==md5sum
        check_entry_hash = db(check_entry_query).select(newsletter_logs.ALL)

        if len(check_entry_hash) <= 0:
            newsletter_logs.insert(hash=md5sum,start=start,end=end,newsletter_id=key,count=count[key])
        else:
            logging.warning('The entry already exist, skipping...')
            continue
        i += 1
        ti += count[key]

    end_epoch = iso8601_to_epoch(end)
    lastrun_db = db(newsletter_meta.key == 'lastrun').select()
    if not lastrun_db:
        newsletter_meta.insert(key='lastrun',value=end_epoch)
    else:
        db(newsletter_meta.key == 'lastrun').update(key='lastrun', value=end_epoch)

    if args.commit:
        db.commit()
        logging.info("A total of %s unique newsletter entries (out of %s processed views) have been written to database", i, ti)
        logging.info("Lastrun date has been set to %s (%s)", end, end_epoch)
    else:
        logging.info("As requested: None of the %s unique newsletter entries (out of %s processed views) have been written", i, ti)
        logging.warning('Use "-c/--commit" to actually write results to the database')

if args.verbose:
    for row in db(newsletter_logs).select():
        print(row)

    for row in db(newsletter_meta).select():
        print(row)
