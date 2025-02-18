DIFF=pg_wal_lsn_diff
LAST_LOC=pg_last_wal_receive_lsn
CURRENT_LOC=pg_current_wal_lsn

psql_repl_status=$(echo "WITH slots AS (SELECT slot_name, slot_type, coalesce(restart_lsn, '0/0'::pg_lsn) AS slot_lsn, coalesce(${DIFF}(coalesce(${LAST_LOC}(), ${CURRENT_LOC}()), restart_lsn),0) AS delta, active FROM pg_replication_slots) SELECT *, pg_size_pretty(delta) AS delta_pretty FROM slots; " | su - postgres -c "psql -d postgres -A -t -F' '")

slot_name=$(echo ${psql_repl_status} | awk '{print $1}')
slot_type=$(echo ${psql_repl_status} | awk '{print $2}')
slot_lsn=$(echo ${psql_repl_status} | awk '{print $3}')
delta=$(echo ${psql_repl_status} | awk '{print $4}')
active=$(echo ${psql_repl_status} | awk '{print $5}')
delta_pretty=$(echo ${psql_repl_status} | awk '{print $6}')
unit=$(echo ${psql_repl_status} | awk '{print $7}')

echo "postgres_replication_delta{slot_name=\"${slot_name}\"} ${delta}" > /var/lib/prometheus/node-exporter/psql_repl_status.prom
echo "postgres_replication_slot_type{slot_name=\"${slot_name}\",slot_type=\"${slot_type}\"} ${delta}" >> /var/lib/prometheus/node-exporter/psql_repl_status.prom
echo "postgres_replication_slot_lsn{slot_name=\"${slot_name}\",slot_lsn=\"${slot_lsn}\"} ${delta}" >> /var/lib/prometheus/node-exporter/psql_repl_status.prom
echo "postgres_replication_delta_pretty{slot_name=\"${slot_name}\",delta_pretty=\"${delta_pretty}\"} ${delta}" >> /var/lib/prometheus/node-exporter/psql_repl_status.prom
echo "postgres_replication_unit{slot_name=\"${slot_name}\",unit=\"${unit}\"} ${delta}" >> /var/lib/prometheus/node-exporter/psql_repl_status.prom

if [ ${active} == "t" ]; then
    echo "postgres_replication_active{slot_name=\"${slot_name}\"} 1" >> /var/lib/prometheus/node-exporter/psql_repl_status.prom
else
    echo "postgres_replication_active{slot_name=\"${slot_name}\"} 1" >> /var/lib/prometheus/node-exporter/psql_repl_status.prom
fi
