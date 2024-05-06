#!/bin/bash

config="/etc/cmk.secret"
cmk="/usr/local/bin/cmk.sh"
prom_path="/var/lib/prometheus/node-exporter/cmk.prom"
json_path="/var/www/html/cmk.json"

hosts=$(cat "${config}" | "${cmk}" lsf okfmon fds-automation /fragdenstaat | awk '{print $2}')

host_count=0
services_count=0
services_problems_count=0
critical_services_count=0
warning_services_count=0
unknown_services_count=0
hosts_offline_count=0

if [ "${1}" != "-q" ]; then
  echo "FragDenStaat Status:"
  echo ""
  printf "%-21s %-10s %-10s %-5s %-5s %-5s\n" Server Status Services CRIT WARN UNKNOWN
fi

for i in $hosts; do
  host_count=$((host_count+1))

  host_status=$(cat "${config}" | "${cmk}" get okfmon fds-automation ${i} | jq '.ok .extensions .is_offline')
  if [ "${host_status}" == "false" ]; then
    host_status="online"
  else
    host_status="offline"
    hosts_offline_count=$((hosts_offline_count+1))
  fi

  services_total=$(cat "${config}" | "${cmk}" services okfmon fds-automation ${i} | jq '.ok .value[] .id' | wc -l)
  services_count=$((services_count+services_total))

  critical_services=$(cat "${config}" | "${cmk}" service_problems okfmon fds-automation ${i} | jq '.ok .value[] .extensions | select( .state == 2 and .acknowledged == 0 ).description' | wc -l || echo 0)
  warning_services=$(cat "${config}" | "${cmk}" service_problems okfmon fds-automation ${i} | jq '.ok .value[] .extensions | select( .state == 1 and .acknowledged == 0 ).description' | wc -l || echo 0)
  unknown_services=$(cat "${config}" | "${cmk}" service_problems okfmon fds-automation ${i} | jq '.ok .value[] .extensions | select( .state == 3 and .acknowledged == 0 ).description' | wc -l || echo 0)

  critical_services_count=$((critical_services_count+critical_services))
  warning_services_count=$((warning_services_count+warning_services))
  unknown_services_count=$((unknown_services_count+unknown_services))
  services_problems=$((critical_services+warning_services+unknown_services))
  services_problems_count=$((services_problems_count+services_problems))

  if [ "${1}" != "-q" ]; then
    printf "%20s: %-10s %-10s %-5s %-5s %-5s\n" ${i} ${host_status} ${services_total} ${critical_services} ${warning_services} ${unknown_services}
  fi
done

if [ "${1}" != "-q" ]; then
  echo ""
  echo "${host_count} hosts with ${services_count} services and ${services_problems_count} problems found. ${hosts_offline_count} hosts are offline."
fi

if [ ${hosts_offline_count} -eq 0 ]; then
  if [ ${services_problems_count} -eq 0 ]; then
    if [ "${1}" != "-q" ]; then
      echo "OK: Have a nice day"
    fi
    errorlevel=0
  else
    if [ ${critical_services_count} -eq 0 ]; then
      if [ "${1}" != "-q" ]; then
        echo "WARN: ${warning_services_count} Problems and ${unknown_services_count} unknown states found, please investigate"
      fi
      errorlevel=1
    else
      if [ "${1}" != "-q" ]; then
        echo "CRIT: ${critical_services_count} severe problems found, please investigate immediately"
      fi
      errorlevel=2
    fi
  fi
else
  if [ "${1}" != "-q" ]; then
    echo "CRIT: ${hosts_offline_count} hosts are offline"
  fi
  errorlevel=3
fi

if [ "${json_path}" ]; then
  echo "{ \"timestamp\": $(date +%s), \"hosts\": ${host_count}, \"hosts_offline\": ${hosts_offline_count}, \"services\": ${services_count}, \"problems\": ${services_problems_count}, \"unknown_services\": ${unknown_services_count}, \"warning_services\": ${warning_services_count}, \"critical_services\": ${critical_services_count} }" > "${json_path}"
fi

if [ "${prom_path}" ]; then
  cat << EOF > "${prom_path}"
cmk_hosts ${host_count}
cmk_hosts_offline ${hosts_offline_count}
cmk_services ${services_count}
cmk_problems ${services_problems_count}
cmk_unknown ${unknown_services_count}
cmk_warning ${warning_services_count}
cmk_critical ${critical_services_count}
cmk_last_check $(date +%s)

EOF
fi

exit ${errorlevel}
