#!/bin/bash
echo "################ Starting postix ###################"

#run rsyslog daemon
systemctl restart rsyslog

#create a storage directory
mkdir -p /storage/postfix-is

#postconf to check
postconf -e "inet_protocols=ipv4"

#create an IS instance
postmulti -e init
postmulti -I postfix-is -G mta -e create queue_directory='/storage/postfix-is'

#patch original master.cf
patch /etc/postfix/master.cf /etc/postfix-is/original-master.patch

# enable and start
postmulti -i postfix-is -e enable
postfix start

tail -f /var/log/maillog
