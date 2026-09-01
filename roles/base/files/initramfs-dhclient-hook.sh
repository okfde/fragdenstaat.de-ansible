#!/bin/sh

PREREQ=""

prereqs()
{
        echo "$PREREQ"
}

case $1 in
prereqs)
        prereqs
        exit 0
        ;;
esac

if [ ! -x /sbin/dhclient ]; then
        exit 0
fi

. /usr/share/initramfs-tools/scripts/functions
. /usr/share/initramfs-tools/hook-functions

mkdir -p $DESTDIR/etc/dhcp/dhclient-exit-hooks.d/
cp -a /etc/dhcp/dhclient-exit-hooks.d/rfc3442-classless-routes $DESTDIR/etc/dhcp/dhclient-exit-hooks.d/
