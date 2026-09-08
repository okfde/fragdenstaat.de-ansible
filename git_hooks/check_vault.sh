#!/bin/bash

FILES='secret(s?)\.y(a?)ml|vpnclients\.y(a?)ml|\.vault|\.vault.y(a?)ml'

for f in $(git diff --cached --name-only | grep -E ${FILES}); do
    if ! git show :${f} | head -n 1 | grep 'ANSIBLE_VAULT'; then
	echo "${f} is an unencrypted vault file, rejecting..."
	echo "Please encrypt via 'ansible-vault' and try again."
	exit 1
    fi
done

exit 0
