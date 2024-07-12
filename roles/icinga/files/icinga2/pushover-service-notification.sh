#!/bin/sh
################################################################################
# Pushover service notification plugin for icinga2                             #
# Copyright (c) 2021 Frostbyte <frostbytegr@gmail.com>                         #
#                                                                              #
# Credits:                                                                     #
# <brian@aljex.com> - url encode function                                      #
# <info@icinga.com> - sample code and formatting for notification plugins      #
#                                                                              #
# This program is free software: you can redistribute it and/or modify         #
# it under the terms of the GNU General Public License as published by         #
# the Free Software Foundation, either version 3 of the License, or            #
# (at your option) any later version.                                          #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program.  If not, see <http://www.gnu.org/licenses/>.        #
################################################################################

# Usage helper function
usage() {
cat << EOF
Usage:
$0 -k <pushover_user_key> -p <pushover_api_token> -t \$notification.type\$ -l \$host.name\$ -n \$host.display_name\$ -e \$service.name\$ -u \$service.display_name\$ -s \$service.state\$ -o \$service.output\$ -d \$icinga.long_date_time\$ [ -4 \$address\$ ] [ -6 \$address6\$ ] [ -b \$notification.author\$ ] [ -c \$notification.comment\$ ] [ -i \$notification_icingaweb2url\$ ] [ -v ]
Example: $0 -k 1234567890abcdefghijklmnopqrst -p 1234567890abcdefghijklmnopqrst -t "Recovery" -l "zawarudo.jojos" -n "zawarudo" -e "ssh" -u "SSH" -s "OK" -o "SSH OK - OpenSSH_8.0 (protocol 2.0)" -d "0000-00-00 00:00:00 +0200" -4 "192.0.2.1" -6 "2001:db8::1" -b "Dio Brando" -c "You were expecting a comment, but it was me, Dio!" -i "http://127.0.0.1/icingaweb2" -v
EOF
exit 3
}

# Input error helper function
inputError() {
	# Throw supplied error message and exit
	echo "$1"
	exit 3
}

# URL encoding function
urlEncode() {
	local LANG=C i=0 c e s="$1"
	while [ $i -lt ${#1} ]; do
		[ "$i" -eq 0 ] || s="${s#?}"
		c=${s%"${s#?}"}
		[ -z "${c#[[:alnum:].~_-]}" ] || c=$(printf '%%%02X' "'$c")
		e="${e}${c}"
		i=$((i + 1))
	done
	echo "$e"
}

# Parse user-supplied arguments
[ $# -eq 0 ] && usage
while getopts ":k:p:t:l:n:e:u:s:o:d:4:6:b:c:i:v" inputArgs; do
	case "${inputArgs}" in
		k) pushoverUserKey="${OPTARG}" ;;
		p) pushoverApiToken="${OPTARG}" ;;
		t) notificationType="${OPTARG}" ;;
		l) notificationHostName="${OPTARG}" ;;
		n) notificationHostDisplayName="${OPTARG}" ;;
		e) notificationServiceName="${OPTARG}" ;;
		u) notificationServiceDisplayName="${OPTARG}" ;;
		s) notificationState="${OPTARG}" ;;
		o) notificationOutput="${OPTARG}" ;;
		d) notificationLongDateTime="${OPTARG}" ;;
		4) notificationHostAddress="${OPTARG}" ;;
		6) notificationHostAddress6="${OPTARG}" ;;
		b) notificationAuthor="${OPTARG}" ;;
		c) notificationComment="${OPTARG}" ;;
		i) notificationIcingaweb2URL="${OPTARG}" ;;
		v) verboseOutput=true ;;
		*) usage ;;
	esac
done
shift $((OPTIND-1))

# Validate user-supplied arguments
[ -z "$pushoverUserKey" ] && inputError "The pushover user key value cannot be empty."
[ -z "$pushoverApiToken" ] && inputError "The pushover api token value cannot be empty."
[ -z "$notificationType" ] && inputError "The notification type value cannot be empty."
[ -z "$notificationHostName" ] && inputError "The host name value cannot be empty."
[ -z "$notificationHostDisplayName" ] && inputError "The host display name value cannot be empty."
[ -z "$notificationServiceName" ] && inputError "The service name value cannot be empty."
[ -z "$notificationServiceDisplayName" ] && inputError "The service display name value cannot be empty."
[ -z "$notificationState" ] && inputError "The service state value cannot be empty."
[ -z "$notificationOutput" ] && inputError "The service output value cannot be empty."
[ -z "$notificationLongDateTime" ] && inputError "The long date time value cannot be empty."
[ ! -z "$notificationComment" ] && [ -z "$notificationAuthor" ] && inputError "The author value cannot be empty, if the comment value was given."
[ ! -z "$notificationAuthor" ] && [ -z "$notificationComment" ] && inputError "The comment value cannot be empty, if the author value was given."

# Construct the notification title
notificationTitle="[${notificationType}] ${notificationServiceDisplayName} on ${notificationHostDisplayName} is ${notificationState}!"

# Construct the notification message
notificationMessage="***** Service Monitoring on $(hostname) *****\n\n${notificationServiceDisplayName} on ${notificationHostDisplayName} is ${notificationState}!\n\nInfo:    ${notificationOutput}\n\nWhen:    ${notificationLongDateTime}\nService: ${notificationServiceName}\nHost:    ${notificationHostName}"
[ -z "$notificationHostAddress" ] || notificationMessage="${notificationMessage}\nIPv4:    ${notificationHostAddress}"
[ -z "$notificationHostAddress6" ] || notificationMessage="${notificationMessage}\nIPv6:    ${notificationHostAddress6}"
[ -z "$notificationComment" ] || notificationMessage="${notificationMessage}\n\nComment by ${notificationAuthor}:\n  ${notificationComment}"
[ -z "$notificationIcingaweb2URL" ] || notificationMessage="${notificationMessage}\n\n${notificationIcingaweb2URL}/monitoring/service/show?host=$(urlEncode "${notificationHostName}")&service=$(urlEncode "${notificationServiceName}")"
notificationMessage=$(echo -e "$notificationMessage")

# Send the push notification
result=$(curl -w "\n%{http_code}" -s -F user="$pushoverUserKey" -F token="$pushoverApiToken" -F title="$notificationTitle" -F message="$notificationMessage" https://api.pushover.net/1/messages)
pushoverHttpCode=$(tail -n1 <<< "$result")
pushoverResponse=$(sed '$ d' <<< "$result")

# If verbose output was requested
[ -z "$verboseOutput" ] || {
	# Throw a warning for any surpassed character limits
	[ ${#notificationTitle} -gt 250 ] && echo -e "WARNING: Notification title exceeds 250 characters\n"
	[ ${#notificationMessage} -gt 1024 ] && echo -e "WARNING: Notification message exceeds 1024 characters\n"

	# Evaluate notification success
	if [ $pushoverHttpCode -eq 200 ]; then
		pluginResult="succeeded"
	else
		pluginResult="failed with HTTP code $pushoverHttpCode\nPushover response: $pushoverResponse"
	fi

	# Provide detailed information
	echo -e "Title (${#notificationTitle} characters):\n$notificationTitle\n\nMessage (${#notificationMessage} characters):\n$notificationMessage\n\nPush notification $pluginResult"
}

# Exit
exit 0
