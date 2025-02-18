#!/bin/bash

if [ -z ${1} ]; then
  es="localhost"
else
  es=${1}
fi

health=$(curl -s http://${es}:9200/_cat/health)

if [ $? != 0 ]; then
  echo "es_status_ping 0" > /var/lib/prometheus/node-exporter/es_status.prom
  exit 1
else
  echo "es_status_ping 1" > /var/lib/prometheus/node-exporter/es_status.prom
fi

epoch=$(echo ${health} | awk '{print $1}')
cluster=$(echo ${health} | awk '{print $3}')
status=$(echo ${health} | awk '{print $4}')

case "${status}" in
  "green")
    status=0
  ;;
  "yellow")
    status=1
  ;;
  "red")
    status=2
  ;;
  *)
    status=3
  ;;
esac

node_total=$(echo ${health} | awk '{print $5}')
node_data=$(echo ${health} | awk '{print $6}')
shards=$(echo ${health} | awk '{print $7}')
pri=$(echo ${health} | awk '{print $8}')
relo=$(echo ${health} | awk '{print $9}')
esinit=$(echo ${health} | awk '{print $10}')
unassign=$(echo ${health} | awk '{print $11}')
pending_tasks=$(echo ${health} | awk '{print $12}')
max_task_wait_time=$(echo ${health} | awk '{print $13}')

if [ ${max_task_wait_time} == "-" ]; then
  max_task_wait_time=0
fi

active_shards_percent=$(echo ${health} | awk '{print $14}' | sed 's/%//g')

echo "es_status_epoch{cluster=\"${cluster}\"} ${epoch}" >> /var/lib/prometheus/node-exporter/es_status.prom
echo "es_status_state{cluster=\"${cluster}\"} ${status}" >> /var/lib/prometheus/node-exporter/es_status.prom
echo "es_status_node_total{cluster=\"${cluster}\"} ${node_total}" >> /var/lib/prometheus/node-exporter/es_status.prom
echo "es_status_node_data{cluster=\"${cluster}\"} ${node_data}" >> /var/lib/prometheus/node-exporter/es_status.prom
echo "es_status_shards{cluster=\"${cluster}\"} ${shards}" >> /var/lib/prometheus/node-exporter/es_status.prom
echo "es_status_relo{cluster=\"${cluster}\"} ${relo}" >> /var/lib/prometheus/node-exporter/es_status.prom
echo "es_status_init{cluster=\"${cluster}\"} ${esinit}" >> /var/lib/prometheus/node-exporter/es_status.prom
echo "es_status_unassign{cluster=\"${cluster}\"} ${unassign}" >> /var/lib/prometheus/node-exporter/es_status.prom
echo "es_status_pending_tasks{cluster=\"${cluster}\"} ${pending_tasks}" >> /var/lib/prometheus/node-exporter/es_status.prom
echo "es_status_max_task_wait_time{cluster=\"${cluster}\"} ${max_task_wait_time}" >> /var/lib/prometheus/node-exporter/es_status.prom
echo "es_status_active_shards_percent{cluster=\"${cluster}\"} ${active_shards_percent}" >> /var/lib/prometheus/node-exporter/es_status.prom
