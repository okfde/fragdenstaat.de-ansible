#!/bin/bash

cd /usr/local/bin/newsletter_info/
sudo -u postgres ./create_database.sh > /dev/null
sudo -u postgres ./bin/python3 ./get_newsletter_info.py -c
