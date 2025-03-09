#! /bin/bash

BOOTUP=mono
LOGFILE="/tmp/ansible.log"
RES_COL=70
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"

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

    return $STEP_OK
}

echo "" > ${LOGFILE}

for i in playbooks/*.yml; do
    step "Running ${i} ${@}"
    try ansible-playbook ./${i} ${@} >> ${LOGFILE}
    next
done

cat ${LOGFILE}
