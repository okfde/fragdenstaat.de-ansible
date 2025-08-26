#! /bin/bash

BOOTUP=mono
LOGFILE="/tmp/ansible.log"
PROMFILE="/tmp/ansible.prom"
RES_COL=70
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"

TIME_TOTAL=0

echo_success() {
    [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
    echo -n "  ["
    [ "$BOOTUP" = "color" ] && $SETCOLOR_SUCCESS
    echo -n $"  OK  "
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 0
}

echo_failure() {
    [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
    echo -n "  ["
    [ "$BOOTUP" = "color" ] && $SETCOLOR_FAILURE
    echo -n $"FAILED"
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 1
}

step() {
    echo -n "$@" | awk '{printf "%-'${RES_COL}'s", $0}'
    echo "" >> "${LOGFILE}"
    echo "********************************************************************************" >> ${LOGFILE}
    echo "$(date)" >> "${LOGFILE}"
    echo "$*" >> "${LOGFILE}"
    echo "********************************************************************************" >> ${LOGFILE}

    STEP_NAME="$@"
    STEP_START=$(date +"%s")

    STEP_OK=0
    STEP_NAME="$@"
    [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$
}

try() {
    "$@" &>> "${LOGFILE}"

    # Check if command failed and update $STEP_OK if so.
    local EXIT_CODE=$?

    if [[ $EXIT_CODE -ne 0 ]]; then
        STEP_OK=$EXIT_CODE
        [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$

        if [[ -n $LOG_STEPS ]]; then
            local FILE=$(readlink -m "${BASH_SOURCE[1]}")
            local LINE=${BASH_LINENO[0]}

            echo "$FILE: line $LINE: Command \`$*' failed with exit code $EXIT_CODE." >> "${LOGFILE}"
        fi
    fi

    return $EXIT_CODE
}

next() {
    [[ -f /tmp/step.$$ ]] && { STEP_OK=$(< /tmp/step.$$); rm -f /tmp/step.$$; }
    [[ $STEP_OK -eq 0 ]]  && echo_success || echo_failure
    echo
    echo "********************************************************************************" >> ${LOGFILE}

    STEP_END=$(date +"%s")
    STEP_TIME=$(( ${STEP_END} - ${STEP_START} ))
    TIME_TOTAL=$(( ${STEP_TIME} + ${TIME_TOTAL} ))
    STEP_NAME_SAVE=$(echo ${STEP_NAME} | \
        sed 's/Running//g' | \
        sed 's/playbooks//g' | \
        sed 's/yml//g' | \
        sed 's/--check//g' | \
        sed 's/--//g' | \
        sed 's/ //g' | \
        sed 's/(//g' | \
        sed 's/)//g' | \
        sed 's/\.//g' | \
        sed 's|/||g' )
    
    cat ${LOGFILE} | \
        grep -e failed= \
            -e changed= \
            -e unreachable= \
            -e rescued= \
            -e skipped= \
            -e ok= \
            -e ignored= | \
        sed 's/\s\+/=/g' | \
        awk -v step="${STEP_NAME_SAVE}" -F'[:=]' \
            '{ 
                print "ansible_"$4"{hostname=\""$1"\",task=\""step"\"} "$5" \
                \nansible_"$6"{hostname=\""$1"\",task=\""step"\"} "$7" \
                \nansible_"$8"{hostname=\""$1"\",task=\""step"\"} "$9" \
                \nansible_"$10"{hostname=\""$1"\",task=\""step"\"} "$11" \
                \nansible_"$12"{hostname=\""$1"\",task=\""step"\"} "$13" \
                \nansible_"$14"{hostname=\""$1"\",task=\""step"\"} "$15" \
                \nansible_"$16"{hostname=\""$1"\",task=\""step"\"} "$17 \
            } ' >> ${PROMFILE}

    return $STEP_OK
}

echo "" > ${LOGFILE}

for i in playbooks/*.yml; do
    step "Running ${i} ${@}"
    try ansible-playbook ./${i} ${@} >> ${LOGFILE}
    next
done

echo "ansible_totaltime_seconds{hostname=\"$(hostname)\"} ${TIME_TOTAL}" >> ${PROMFILE}

echo "See ${LOGFILE} for details..."
if [ ! -d "/var/lib/prometheus/node-exporter/" ]; then
    cat ${PROMFILE} | awk '{$1=$1;print}' | sort | uniq -u -z
else
    cat ${PROMFILE} | awk '{$1=$1;print}' | sort | uniq -u -z > /var/lib/prometheus/node-exporter/ansible_playbooks.prom
fi

rm ${LOGFILE}
rm ${PROMFILE}
