#!/bin/bash

echo "SELECT 'CREATE DATABASE newsletter_info' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'newsletter_info')\gexec" | psql
