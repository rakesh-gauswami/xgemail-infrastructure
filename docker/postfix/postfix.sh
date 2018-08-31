#!/bin/bash
# chkconfig: 2345 81 31
# description: postfix3-sophos

# Source function library.
. /etc/rc.d/init.d/functions

start()
{
    echo -n $"Starting $prog: "

    #create a storage directory
    mkdir -p /storage/postfix-is

    #postconf to check
    postconf -e "inet_protocols=ipv4"

    #create an IS instance
    postmulti -e init
    postmulti -I postfix-is -G mta -e create queue_directory='/storage/postfix-is'

    #patch original master.cf
    original="/etc/postfix/master.cf"
    patch="/etc/postfix-is/original-master.patch"
    patch -p0 -N --dry-run --silent ${original} ${patch} 2>/dev/null
    if [ $? -eq 0 ];
    then
        #apply the patch
        patch -p0 -N ${original} ${patch}
    fi

    # prepare postmaps
    exec "/etc/postfix-is/build_maps.sh"

    # enable and start
    postmulti -i postfix-is -e enable
    postfix start
    systemctl restart postfix
}

stop()
{
    # This script is not used to stop postfix3-sophos
    echo -n $"Use 'postfix stop' to stop $prog: "
}

status()
{
    postfix status
}

restart()
{
    postfix stop
    postfix start
}

case "$1" in
    start|stop|status|restart)
        $1 ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 2 ;;
esac
