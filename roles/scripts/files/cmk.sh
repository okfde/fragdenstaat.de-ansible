#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

URL_SRV="https://mon.okfn.de/"

#When creating a new host in checkmk,
#remove domain from string and turn all chars lowercase
#(in function convertHostname)
DOMAIN=".okfn.de"

function usage()
{
	echo -e "usage:"
	echo -e "\t${RED}Get information about checkmk host:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) get site user host${NC}"
	echo -e "\t\tsite = checkmk site name"
	echo -e "\t\tuser = username for connection"
	echo -e "\t\thost = checkmk hostname"
	echo -e "\t\tNote: path is not required as hosts have unique IDs"
	echo -e "\n\t\tExample (get host myhost1 from checkmk test site):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) get test automation myhost1${NC}"

	echo -e "\n\t${RED}Get information about checkmk services:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) services site user host${NC}"
	echo -e "\t\tsite = checkmk site name"
	echo -e "\t\tuser = username for connection"
	echo -e "\t\thost = checkmk hostname"
	echo -e "\t\tNote: path is not required as hosts have unique IDs"
	echo -e "\n\t\tExample (services host myhost1 from checkmk test site):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) services test automation myhost1${NC}"

	echo -e "\n\t${RED}Get information about checkmk service problems:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) service_problems site user host${NC}"
	echo -e "\t\tsite = checkmk site name"
	echo -e "\t\tuser = username for connection"
	echo -e "\t\thost = checkmk hostname"
	echo -e "\t\tNote: path is not required as hosts have unique IDs"
	echo -e "\n\t\tExample (service_problems host myhost1 from checkmk test site):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) service_problems test automation myhost1${NC}"

	echo -e "\n\t${RED}Set tag on host:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) settag site user host etag tag_group tag_group_value${NC}"
	echo -e "\t\tsite = checkmk site name"
  echo -e "\t\tuser = username for connection"
  echo -e "\t\thost = checkmk hostname"
	echo -e "\t\tetag = etag value of hostname (use get to acquire this value)"
  echo -e "\t\ttag_group = name of tag group"
  echo -e "\t\ttag_group_value = new value from tag_group that is set for hostname"

	echo -e "\n\t${RED}Create checkmk host in folder:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) create site user host folder [ip]${NC}"
	echo -e "\t\tsite = checkmk site name"
	echo -e "\t\tuser = username for connection"
	echo -e "\t\thost = checkmk hostname"
	echo -e "\t\tfolder = path to folder where host is to be created"
	echo -e "\t\tip = if given it will be used as static ip instead of dhcp"
	echo -e "\n\t\tExample (add checkmk host test1 to folder /folder1 and use dhcp):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) create test automation test1 /folder1${NC}"
	echo -e "\n\t\tExample (add checkmk host test2 to folder /folder1 and use static ip 192.168.1.1):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) create test automation test2 "/folder1" "192.168.1.1" ${NC}"

	echo -e "\n\t${RED}Perform checkmk discovery on host:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) discover site user host type${NC}"
	echo -e "\t\tsite = checkmk site name"
	echo -e "\t\tuser = username for connection"
	echo -e "\t\thost = checkmk hostname"
	echo -e "\t\ttype = discovery type: 'new', 'remove', 'fix_all', 'refresh' or 'only_host_labels'"
	echo -e "\n\t\tExample (perform fix_all discovery on host test1):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) discover test automation test1 fix_all ${NC}"

	echo -e "\n\t${RED}Activate changes on site:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) activate site user [false|true] ${NC}"
	echo -e "\t\tsite = checkmk site name where changes are to be activated"
	echo -e "\t\tuser = username for connection"
	echo -e "\t\tforce = can be \"false\" or \"true\". If true then the activation will commit foreign user changes."
	echo -e "\n\t\tExample: Try to activate changes on site test and exit if other users also made changes"
	echo -e "\t\t\$ ${GREEN}$(basename $0) activate test automation ${NC}"
	echo -e "\t\t\$ ${GREEN}$(basename $0) activate test automation false ${NC}"
	echo -e "\n\t\tExample: Activate changes on site test even if they are from foreign users"
	echo -e "\t\t\$ ${GREEN}$(basename $0) activate test automation true ${NC}"

	echo -e "\n\t${RED}Delete checkmk host:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) delete site user host ${NC}"
	echo -e "\t\tsite = checkmk site name"
	echo -e "\t\tuser = username for connection"
	echo -e "\t\thost = checkmk hostname"
	echo -e "\n\t\tExample (delete checkmk host test1):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) delete test automation test1 ${NC}"
	echo -e "\t\tNote: path is not required as hosts have unique IDs"

	echo -e "\n\t${RED}List checkmk hosts and folders in path:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) ls site user path ${NC}"
	echo -e "\t\tsite = checkmk site name"
	echo -e "\t\tuser = username for connection"
	echo -e "\t\tpath = path in checkmk to list"
	echo -e "\n\t\tExample (list checkmk host and folders in /):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) ls test automation / ${NC}"

	echo -e "\n\t${RED}List checkmk folders in path:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) lsd site user path ${NC}"
	echo -e "\t\tsite = checkmk site name"
	echo -e "\t\tuser = username for connection"
  echo -e "\t\tpath = path in checkmk to list"
	echo -e "\n\t\tExample (list checkmk folders in /):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) lsd test automation / ${NC}"

	echo -e "\n\t${RED}List checkmk hosts in path:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) lsf site user path ${NC}"
	echo -e "\t\tsite = checkmk site name"
	echo -e "\t\tuser = username for connection"
  echo -e "\t\tpath = path in checkmk to list"
	echo -e "\n\t\tExample (lisf checkmk hosts in /):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) lsf test automation / ${NC}"
	echo -e ""
	echo -e "For better view, pipe the output of this command to ${RED}jq${NC} (command line JSON processor)."
	echo -e "Don't end paths with extra /. For example \"/folder1\" is ok, while \"/folder1/\" is not."

	echo -e "\n\t${RED}Acknowledge host problem:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) ack_host site user host${NC}"
	echo -e "\t\tsite = checkmk site name"
	echo -e "\t\tuser = username for connection"
	echo -e "\t\thost = checkmk hostname"
	echo -e "\t\tNote: path is not required as hosts have unique IDs"
	echo -e "\n\t\tExample (services host myhost1 from checkmk test site):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) ack_host test automation myhost1${NC}"

	echo -e "\n\t${RED}Acknowledge service problem:${NC}"
	echo -e "\t\$ ${ORANGE}$(basename $0) ack_service site user host servicedescription${NC}"
	echo -e "\t\tsite = checkmk site name"
	echo -e "\t\tuser = username for connection"
	echo -e "\t\thost = checkmk hostname"
	echo -e "\t\tservicedescription = checkmk service description"
	echo -e "\t\tNote: path is not required as hosts have unique IDs"
	echo -e "\n\t\tExample (service_problems host myhost1 from checkmk test site):"
	echo -e "\t\t\$ ${GREEN}$(basename $0) ack_service test automation myhost1 \"CPU load\"${NC}"
}

function ack_host()
{
	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")
  DATA=$(echo "{ \"acknowledge_type\": \"host\", \"sticky\": \"true\", \"persistent\": \"false\", \"notify\": \"false\", \"comment\": \"This was expected.\", \"host_name\": \"${HOST}\" }")

	RES=$(echo "$HEADER" | curl -w "\n%{http_code}" -X 'POST' \
	  "${URL}/domain-types/acknowledge/collections/host" \
	  -H 'accept: application/json' \
	  -H @- \
	  -H 'Content-Type: application/json' \
	  -d "${DATA}" \
	  2>/dev/null )

	#Get return code from last line
	RC=$(echo "$RES" | tail -n1)

	#Get result from last-1 line
	CONT=$(echo "$RES" | tail -n2 | head -n1)

	#Get header (every line except last two)
	HEADER_RCV=$(echo "$RES" | head -n -2 | dos2unix)

	#Get etag from header
	ETAG=$(echo "$HEADER_RCV" | grep -i "etag" | cut -d' ' -f2 | tr -d '"')

	#echo "etag: ${ETAG}"

	#OK
	if (( "$RC" == 200 )); then
		#echo -e "{\"ok\" : ${CONT} }"
		echo -e "{ \"rc\" : \"${RC}\", \"etag\" : \"${ETAG}\", \"ok\" : ${CONT} }"

	#Wrong secret
        elif (( "$RC" == 401 )); then
                echo "{\"failure\" : \"wrong username or secret!\"}"
                exit 1

	#Host not found
        else
		echo "${CONT}"
        fi
}

function ack_service()
{
	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")
  DATA=$(echo "{ \"acknowledge_type\": \"service\", \"sticky\": \"true\", \"persistent\": \"false\", \"notify\": \"false\", \"comment\": \"This was expected.\", \"host_name\": \"${HOST}\", \"service_description\": \"${SERVICE}\" }")

	RES=$(echo "$HEADER" | curl -w "\n%{http_code}" -X 'POST' \
	  "${URL}/domain-types/acknowledge/collections/service" \
	  -H 'accept: application/json' \
	  -H @- \
	  -H 'Content-Type: application/json' \
	  -d "${DATA}" \
	  2>/dev/null )

	#Get return code from last line
	RC=$(echo "$RES" | tail -n1)

	#Get result from last-1 line
	CONT=$(echo "$RES" | tail -n2 | head -n1)

	#Get header (every line except last two)
	HEADER_RCV=$(echo "$RES" | head -n -2 | dos2unix)

	#Get etag from header
	ETAG=$(echo "$HEADER_RCV" | grep -i "etag" | cut -d' ' -f2 | tr -d '"')

	#echo "etag: ${ETAG}"

	#OK
	if (( "$RC" == 200 )); then
		#echo -e "{\"ok\" : ${CONT} }"
		echo -e "{ \"rc\" : \"${RC}\", \"etag\" : \"${ETAG}\", \"ok\" : ${CONT} }"

	#Wrong secret
        elif (( "$RC" == 401 )); then
                echo "{\"failure\" : \"wrong username or secret!\"}"
                exit 1

	#Host not found
        else
		echo "${CONT}"
        fi
}

function service_problems()
{
	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")

  RES=$(echo "$HEADER" | curl -G -i -w "\n%{http_code}" \
    -X "GET" "${URL}domain-types/service/collections/all?host_name=${HOST}" \
    --data-urlencode "query={\"op\": \"!=\", \"left\": \"state\", \"right\": \"0\"}" \
    --data-urlencode 'columns=host_name' \
    --data-urlencode 'columns=description' \
    --data-urlencode 'columns=state' \
    --data-urlencode 'columns=hard_state' \
    --data-urlencode 'columns=acknowledged' \
    --data-urlencode 'columns=plugin_output' \
    -H "accept: application/json" -H @- 2>/dev/null)

	#Get return code from last line
	RC=$(echo "$RES" | tail -n1)

	#Get result from last-1 line
	CONT=$(echo "$RES" | tail -n2 | head -n1)

	#Get header (every line except last two)
	HEADER_RCV=$(echo "$RES" | head -n -2 | dos2unix)

	#Get etag from header
	ETAG=$(echo "$HEADER_RCV" | grep -i "etag" | cut -d' ' -f2 | tr -d '"')

	#echo "etag: ${ETAG}"

	#OK
	if (( "$RC" == 200 )); then
		#echo -e "{\"ok\" : ${CONT} }"
		echo -e "{ \"rc\" : \"${RC}\", \"etag\" : \"${ETAG}\", \"ok\" : ${CONT} }"

	#Wrong secret
        elif (( "$RC" == 401 )); then
                echo "{\"failure\" : \"wrong username or secret!\"}"
                exit 1

	#Host not found
        else
		echo "${CONT}"
        fi
}

function services()
{
	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")

  RES=$(echo "$HEADER" | curl -G -i -w "\n%{http_code}" \
    -X "GET" "${URL}domain-types/service/collections/all?host_name=${HOST}" \
    --data-urlencode 'columns=host_name' \
    --data-urlencode 'columns=description' \
    --data-urlencode 'columns=check_command_expanded' \
    --data-urlencode 'columns=plugin_output' \
    -H "accept: application/json" -H @- 2>/dev/null)

	#Get return code from last line
	RC=$(echo "$RES" | tail -n1)

	#Get result from last-1 line
	CONT=$(echo "$RES" | tail -n2 | head -n1)

	#Get header (every line except last two)
	HEADER_RCV=$(echo "$RES" | head -n -2 | dos2unix)

	#Get etag from header
	ETAG=$(echo "$HEADER_RCV" | grep -i "etag" | cut -d' ' -f2 | tr -d '"')

	#echo "etag: ${ETAG}"

	#OK
	if (( "$RC" == 200 )); then
		#echo -e "{\"ok\" : ${CONT} }"
		echo -e "{ \"rc\" : \"${RC}\", \"etag\" : \"${ETAG}\", \"ok\" : ${CONT} }"

	#Wrong secret
        elif (( "$RC" == 401 )); then
                echo "{\"failure\" : \"wrong username or secret!\"}"
                exit 1

	#Host not found
        else
		echo "${CONT}"
        fi
}

function get()
{
	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")

	RES=$(echo "$HEADER" | curl -i -w "\n%{http_code}" -X "GET" "${URL}/objects/host_config/${HOST}?effective_attributes=true" -H "accept: application/json" -H @- 2>/dev/null)

	#Get return code from last line
	RC=$(echo "$RES" | tail -n1)

	#Get result from last-1 line
	CONT=$(echo "$RES" | tail -n2 | head -n1)

	#Get header (every line except last two)
	HEADER_RCV=$(echo "$RES" | head -n -2 | dos2unix)

	#Get etag from header
	ETAG=$(echo "$HEADER_RCV" | grep -i "etag" | cut -d' ' -f2 | tr -d '"')

	#echo "etag: ${ETAG}"

	#OK
	if (( "$RC" == 200 )); then
		#echo -e "{\"ok\" : ${CONT} }"
		echo -e "{ \"rc\" : \"${RC}\", \"etag\" : \"${ETAG}\", \"ok\" : ${CONT} }"

	#Wrong secret
        elif (( "$RC" == 401 )); then
                echo "{\"failure\" : \"wrong username or secret!\"}"
                exit 1

	#Host not found
        else
		echo "${CONT}"
        fi
}

function settag()
{
	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")

	#Would clear all attributes not mentioned in request body
	#DATA=$(echo "{ \"attributes\": { \"${TAG_GROUP}\": \"${TAG_GROUP_VALUE}\" }, \"update_attributes\": { \"${TAG_GROUP}\": \"${TAG_GROUP_VALUE}\" }}" )

	#Updates only tag
	DATA=$(echo "{ \"update_attributes\": { \"${TAG_GROUP}\": \"${TAG_GROUP_VALUE}\" }}" )
	#echo "DATA: ${DATA}"

	RES=$(echo "$HEADER" | curl -i -w "\n%{http_code}" -X "PUT" "${URL}/objects/host_config/${HOST}" -H "accept: application/json" -H "If-Match: $ETAG" -H "Content-Type: application/json" -H @- -d "$DATA"  2>/dev/null)

	#Get return code from last line
        RC=$(echo "$RES" | tail -n1)

        #Get result from last-1 line
        CONT=$(echo "$RES" | tail -n2 | head -n1)

        #Get header (every line except last two)
        HEADER_RCV=$(echo "$RES" | head -n -2 | dos2unix)

	#OK
        if (( "$RC" == 200 )); then
                #echo -e "{\"ok\" : ${CONT} }"
                echo -e "{ \"rc\" : \"${RC}\", \"etag\" : \"${ETAG}\", \"ok\" : ${CONT} }"

        #Wrong secret
        elif (( "$RC" == 401 )); then
                echo "{\"failure\" : \"wrong username or secret!\"}"
                exit 1

        #Host not found
        else
                echo "${CONT}"
        fi
}

function create()
{
	#echo "HOST: ${HOST}"
	#echo "FOLDER: ${FOLDER}"
	#echo "IP: ${IP}"

	#If variable IP not zero => use IP
	if [ ! -z "${IP}" ]; then
		DATA="{
		  \"folder\": \"${FOLDER}\",
		  \"host_name\": \"${HOST}\",
		  \"attributes\": {
		    \"ipaddress\": \"${IP}\"
		  }
		}"
	#If variable IP is zero => don't set IP
	else
		DATA="{
                  \"folder\": \"${FOLDER}\",
                  \"host_name\": \"${HOST}\"
                }"
	fi

	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")

	RES=$(echo "$HEADER" | curl -w "\n%{http_code}" -X 'POST' \
	  "${URL}/domain-types/host_config/collections/all" \
	  -H 'accept: application/json' \
	  -H @- \
	  -H 'Content-Type: application/json' \
	  -d "${DATA}" \
	  2>/dev/null )

	#Get return code
	RC=$(echo "$RES" | tail -n1)

	#Get result
	CONT=$(echo "$RES" | head -n1)

	echo "RC: $RC"
	echo "CONT: $CONT"

	# Ok
	if (( "$RC" == 200 )); then
		echo -e "{\"ok\" : ${CONT} }"

	# Wrong secret
	elif (( "$RC" == 401 )); then
		echo "{\"failure\" : \"wrong username or secret!\"}"
		exit 1

	# Else
	else
		echo "${CONT}"
	fi
}

function discover()
{
	# mode is one of the enum values: ['new', 'remove', 'fix_all', 'refresh', 'only_host_labels']"

	DATA="{
          \"mode\": \"${DISCOVER_TYPE}\"
        }"

	#DATA="{
        #  \"mode\": \"refresh\"
        #}"

	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")

        RES=$(echo "$HEADER" | curl -w "\n%{http_code}" -X 'POST' \
          "${URL}/objects/host/${HOST}/actions/discover_services/invoke" \
          -H 'accept: application/json' \
          -H @- \
          -H 'Content-Type: application/json' \
          -d "${DATA}" \
          2>/dev/null )

	#Get return code
        RC=$(echo "$RES" | tail -n1)

        #Get result
        CONT=$(echo "$RES" | head -n1)

        #echo "RC: $RC"
        #echo "CONT: $CONT"

        # Ok
        if (( "$RC" == 200 )); then
                echo -e "{\"ok\" : ${CONT} }"

        # Wrong secret
        elif (( "$RC" == 401 )); then
                echo "{\"failure\" : \"wrong username or secret!\"}"
                exit 1

        # Else
        else
                echo "${CONT}"
        fi
}

function activate()
{
	DATA="{
	  \"redirect\": false,
	  \"sites\": [
	    \"${SITE}\"
	  ],
	  \"force_foreign_changes\": ${FORCE}
	}"

	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")

        RES=$(echo "$HEADER" | curl -w "\n%{http_code}" -X 'POST' \
          "${URL}/domain-types/activation_run/actions/activate-changes/invoke" \
          -H 'accept: application/json' \
          -H @- \
          -H 'Content-Type: application/json' \
          -d "${DATA}" \
          2>/dev/null )

        #Get return code
        RC=$(echo "$RES" | tail -n1)

        #Get result
        CONT=$(echo "$RES" | head -n1)

        #echo "RC: $RC"
        #echo "CONT: $CONT"

        # Ok
        if (( "$RC" == 200 )); then
                echo -e "{\"ok\" : ${CONT} }"

        # Wrong secret
        elif (( "$RC" == 401 )); then
                echo "{\"failure\" : \"wrong username or secret!\"}"
                exit 1

        # Else
        else
                echo "${CONT}"
        fi
}
function delete()
{
	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")

	RES=$(echo "$HEADER" | curl -w "\n%{http_code}" -X 'DELETE' \
          "${URL}/objects/host_config/${HOST}" \
          -H 'accept: */*' \
          -H @- \
          2>/dev/null )

	#Get return code
        RC=$(echo "$RES" | tail -n1)

        #Get result
        CONT=$(echo "$RES" | head -n1)

        #echo "RC: $RC"
        #echo "CONT: $CONT"

        # Ok
        if (( "$RC" == 204 )); then
                echo -e "{\"ok\" : \"No Content: Operation done successfully. No further output.\" }"

        # Wrong secret
        elif (( "$RC" == 401 )); then
                echo "{\"failure\" : \"wrong username or secret!\"}"
                exit 1

        # Else
        else
                echo "${CONT}"
        fi
}
function showAllFolders()
{
	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")

	RES=$(echo "$HEADER" | curl -w "\n%{http_code}" -X 'GET' \
          "${URL}/domain-types/folder_config/collections/all?parent=${FOLDER}&recursive=false&show_hosts=false" \
	  -H 'accept: application/json' \
          -H @- \
          2>/dev/null )

        #Get return code
        RC=$(echo "$RES" | tail -n1)

        #Get result
        CONT=$(echo "$RES" | head -n1)

        #echo "RC: $RC"
        #echo "CONT: $CONT"

        # Ok
        if (( "$RC" == 200 )); then
		#echo -e "{\"ok\" : ${CONT} }"
		#OUT=$(echo -e "{\"ok\" : ${CONT} }" | jq '.ok.value[] | .id,.title' | tr '~' '/' | paste -d' ' - - | column --table --table-columns=dir_id,title)
		#OUT=$(echo -e "{\"ok\" : ${CONT} }" | jq '.ok.value[] | .id,.title' | tr '~' '/' | xargs -L2 printf '%-40s %s\n')
		OUT=$(echo -e "{\"ok\" : ${CONT} }" | jq '.ok.value[] | "d",.id,.title' | tr '~' '/' | xargs -L3 printf '%s %-40s %s\n' | sort -t' ' -k2)

		OUT_NO_WHITESPACES=$(echo ${OUT} | tr -d '[:blank:]')
		if [ -z "$OUT_NO_WHITESPACES" ]; then
			echo "No folders found"
		else
			echo "${OUT}"
		fi

        # Wrong secret
        elif (( "$RC" == 401 )); then
		echo "{\"failure\" : \"wrong username or secret!\"}"
                exit 1

        # Else
        else
                echo "${CONT}"
        fi
}

function showAllHosts()
{
	HEADER=$(echo "Authorization: Bearer ${USER} ${SECRET}")

	RES=$(echo "$HEADER" | curl -w "\n%{http_code}" -X 'GET' \
          "${URL}/objects/folder_config/${FOLDER}/collections/hosts" \
          -H 'accept: application/json' \
          -H @- \
          2>/dev/null )

        #Get return code
        RC=$(echo "$RES" | tail -n1)

        #Get result
        CONT=$(echo "$RES" | head -n1)

        #echo "RC: $RC"
        #echo "CONT: $CONT"

        # Ok
        if (( "$RC" == 200 )); then
                #echo -e "{\"ok\" : ${CONT} }"
		#echo -e "$(echo ${CONT} | jq '.value[].extensions')"
		#echo -e "$(echo ${CONT} | jq '.value[].extensions.attributes.ipaddress')"
                #OUT=$(echo -e "{\"ok\" : ${CONT} }" | jq '.ok.value[] | .id,.title' | tr '~' '/' | paste -d' ' - - | column --table --table-columns=host_id,title)
		#OUT=$(echo -e "{\"ok\" : ${CONT} }" | jq '.ok.value[] | .id,.title' | tr '~' '/' | xargs -L2 printf '%-40s %s\n')
		#OUT=$(echo -e "{\"ok\" : ${CONT} }" | jq '.ok.value[] | "f",.id,.title' | tr '~' '/' | xargs -L3 printf '%s %-40s %s\n' | sort -t' ' -k2)
		OUT=$(echo -e "{\"ok\" : ${CONT} }" | jq '.ok.value[] | "f",.id,.title,.extensions.attributes.ipaddress' | tr '~' '/' | xargs -L4 printf '%s %-40s %s (ip: %s)\n' | sort -t' ' -k2)

		#Remove substring "(ip: )" and whitespaces. If string is empty display nothing is found
		OUT_NO_WHITESPACES=$(echo ${OUT} | sed -r 's/\(ip: \)//' | tr -d '[:blank:]')
                if [ -z "$OUT_NO_WHITESPACES" ]; then
                        echo "No hosts found"
                else
                        echo "${OUT}"
                fi

        # Wrong secret
        elif (( "$RC" == 401 )); then
                echo "{\"failure\" : \"wrong username or secret!\"}"
                exit 1

        # Else
        else
                echo "${CONT}"
        fi
}

# $1 = checkmk site name
function setValidateURL()
{
	if (! echo "$1" | egrep -iq "^[a-zA-Z0-9\-]+$"); then
		echo "Invalid site name!"
		exit 1
	fi

	URL=$(echo "${URL_SRV}/$1/check_mk/api/1.0/")
}

# $1 = folder name
function validateFolder()
{
	if [ -z "$1" ]; then
		echo "Folder cannot be empty string!"
		exit 1
	else
		if ( ! echo "$1" | egrep -iq "^~.*$" ); then
			echo "Invalid folder format!"
			exit 1
		fi
	fi
}

# $1 = selected discovery type
function validateDiscoveryType()
{
	#['new', 'remove', 'fix_all', 'refresh', 'only_host_labels']
	if (! echo "$1" | egrep -iq "^((new)|(remove)|(fix_all)|(refresh)|(only_host_labels))$"); then
		echo "Invalid discovery type! Use: 'new', 'remove', 'fix_all', 'refresh', 'only_host_labels'"
		exit 1
	fi
}

# $1 = IPv4
function validateIP()
{
	if [ ! -z "$1" ]; then
		if ( ! echo "$1" | egrep -iq "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" ); then
			echo "Invalid ip format!"
			exit 1
		fi
	fi
}

#When creating a new host in checkmk,
#remove domain from string and turn all chars lowercase
# $1 = hostname string
# returns new hostname string as stdout
function convertHostname()
{
	#Convert host to lowercase
	#(all checkmk host have lowercase id to avoid additional complexity)
	local HOST=$(echo "$1" | tr '[:upper:]' '[:lower:]')

	#Remove domain name
	local NEW_HOST=${HOST%%$DOMAIN}

	#Return string as stdout
	echo "${NEW_HOST}"
}

# $1 = string for FORCE boolean
# if undefined or empty string then FORCE is false
# else FORCE is tested for values "true" and "false"
function validateForce()
{
	if [ -z "$1" ]; then
		FORCE="false"
	elif [ "$1" != "true" ] && [ "$1" != "false" ]; then
		echo "Force can only be \"true\" or \"false\""
		exit 1
	fi
}

# $1 = site string
function validateSite()
{
	if [ -z "$1" ]; then
		echo "Site cannot be empty string!"
		exit 1
	fi
}

function getSecret()
{
	#################
	#Get password (you can pipe secret to stdin of this process to avoid entering password every time)
	read -s -p "Enter secret: " SECRET
	echo ""

	#Note that different sites on the same server may have different passwords for REST api (automation user).
	#################
}

#If no arguments output usage
if (( "$#" < 1 )); then
	usage
	exit 1
fi

#If one argument and it's -? output usage
if (( "$#" == 1 )); then
        if [ "$1" == "-?" ]; then
                usage
                exit 0
        fi
fi

#String representing operation to lower case
OP=$(echo "$1" | tr '[:upper:]' '[:lower:]')

#Switch by operation:
case "$OP" in
  "ack_host")
	if (( "$#" != 4 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		HOST=$4

		setValidateURL "${URL_SITE}"
		getSecret

		ack_host
		;;
  "ack_service")
	if (( "$#" != 5 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		HOST=$4
    SERVICE=$5

		setValidateURL "${URL_SITE}"
		getSecret

		ack_service
		;;
  "service_problems")
	if (( "$#" != 4 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		HOST=$4

		setValidateURL "${URL_SITE}"
		getSecret

		service_problems
		;;
  "services")
	if (( "$#" != 4 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		HOST=$4

		setValidateURL "${URL_SITE}"
		getSecret

		services
		;;

	"get")
		#echo "get"
		if (( "$#" != 4 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		HOST=$4

		setValidateURL "${URL_SITE}"
		getSecret

		get
		;;

	"settag")
		#echo "settag"
                if (( "$#" != 7 )); then
                        usage
                        exit 1
                fi

                URL_SITE=$2
                USER=$3
                HOST=$4
		ETAG=$5
		TAG_GROUP=$6
		TAG_GROUP_VALUE=$7

                setValidateURL "${URL_SITE}"
                getSecret

		if [ -z "$ETAG" ]; then
			echo "ETAG cannot be empty (use get to acquire ETAG)!"
			exit 1
		fi

		if [ -z "$TAG_GROUP" ]; then
			echo "tag group field cannot be empty"
			exit 1
		fi

		if [ -z "$TAG_GROUP_VALUE" ]; then
			echo "tag group value cannot be empty"
			exit 1
		fi

                settag
                ;;

	"discover")
		#echo "discover"
		if (( "$#" != 5 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		HOST=$4
		DISCOVER_TYPE=$5

		setValidateURL "${URL_SITE}"
		validateDiscoveryType "${DISCOVER_TYPE}"
		getSecret

		discover
		;;

	"delete")
		#echo "delete"
		if (( "$#" != 4 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		HOST=$4

		setValidateURL "${URL_SITE}"
		getSecret

		delete
		;;

	"lsd")
		#echo "show folders"
		if (( "$#" != 4 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		FOLDER=$4

		setValidateURL "${URL_SITE}"

		#Path separators are ~
		FOLDER=$(echo "$FOLDER" | tr '/' '~')
		validateFolder "${FOLDER}"

		getSecret

		showAllFolders
		;;

	"lsf")
		#echo "show files"
		if (( "$#" != 4 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		FOLDER=$4

		setValidateURL "${URL_SITE}"

		#Path separators are ~
		FOLDER=$(echo "$FOLDER" | tr '/' '~')
		validateFolder "${FOLDER}"

		getSecret

		showAllHosts
		;;

	"ls")
		#echo "show files and folders"
		if (( "$#" != 4 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		FOLDER=$4

		setValidateURL "${URL_SITE}"

		#Path separators are ~
		FOLDER=$(echo "$FOLDER" | tr '/' '~')
		validateFolder "${FOLDER}"

		getSecret

		#List all folders
		D=$(showAllFolders)

		#List all hosts
		F=$(showAllHosts)

		#Merge lists, sort by id, remove lines about no folders or hosts found
		echo -e "${D}\n${F}" | sort -t' ' -k2 | grep -iv "No folders found\|No hosts found"
		;;

	"activate")
		#echo "activate"
		if (( "$#" < 3 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		FORCE=$4

		setValidateURL "${URL_SITE}"
		SITE="${URL_SITE}"
		validateSite "${SITE}"

		validateForce "${FORCE}"

		getSecret

		activate
		;;

	"create")
		#echo "create"

		if (( "$#" < 5 )); then
			usage
			exit 1
		fi

		URL_SITE=$2
		USER=$3
		HOST=$4
		FOLDER=$5
		IP=$6

		setValidateURL "${URL_SITE}"

		#When creating a new host in checkmk,
		#remove domain from string and turn all chars lowercase
		HOST="$(convertHostname "$HOST")"

		#Path separators are ~
		FOLDER=$(echo "$FOLDER" | tr '/' '~')
		validateFolder "${FOLDER}"

		#if $IP is not set or empty string => we are using dhcp
		#else => static ip is set

		validateIP "${IP}"

		getSecret

		create
		;;

	*)
		echo "Unknown command!"
		exit 1
		;;
esac

#
#MIT License
#
#Copyright (c) 2021 Blaž Poje
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
#
