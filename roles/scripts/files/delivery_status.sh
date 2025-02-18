#!/bin/bash

cd /tmp/
delivery_status=$(echo "SELECT count(foirequest_foimessage.id) FROM foirequest_foimessage JOIN foirequest_deliverystatus ON foirequest_deliverystatus.message_id = foirequest_foimessage.id WHERE foirequest_foimessage.kind = 'email' AND NOT foirequest_foimessage.is_response AND foirequest_deliverystatus.status = 'sending'" | sudo -u postgres psql -t -d fragdenstaat_de)
delivery_status=$(echo "${delivery_status}" | tr -d '[:blank:]')
echo "foirequest_foimessage_delivery_queue ${delivery_status}" > /var/lib/prometheus/node-exporter/foirequest_delivery_status.prom
