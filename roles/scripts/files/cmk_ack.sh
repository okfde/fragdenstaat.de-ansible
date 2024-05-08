#!/bin/bash

config="/etc/cmk.secret"
cmk="/usr/local/bin/cmk.sh"

hosts=$(cat "${config}" | "${cmk}" lsf okfmon fds-automation /fragdenstaat | awk '{print $2}')

for host in ${hosts}; do
  check=$(cat "${config}" | "${cmk}" get okfmon fds-automation "${host}" | jq ".ok .is_offline")
  if [ "${check}" != "null" ]; then
    printf "%-16s: Host acknowledged\n" ${host}
    cat "${config}" | "${cmk}" ack_host okfmon fds-automation "${host}" > /dev/null 2>&1
  else
    printf "%-16s: No Host issues to acknowledge\n" ${host}
  fi
  service_problems=$(cat "${config}" | "${cmk}" service_problems okfmon fds-automation "${host}" | jq ".ok .value[] .extensions .description")
  if [ -z "${service_problems}" ]; then
    printf "%-17s No services to acknowledge\n" ""
  else
    IFS=$'\n'
    for problem in ${service_problems}; do
      printf "%-17s Service %s acknowledged\n" "" ${problem}
      problem=$(echo "${problem}" | sed 's/"//g')
      cat "${config}" | "${cmk}" ack_service okfmon fds-automation "${host}" "${problem}" > /dev/null 2>&1
    done
  fi
done
