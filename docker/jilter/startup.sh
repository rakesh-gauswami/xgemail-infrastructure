#!/bin/bash

export IPADDRESS=`hostname -i`

#
#Start the jilter service
exec $JAVA_HOME/bin/java \
		-Dlogback.configurationFile=/data/conf/logback.xml \
    -Dcom.sun.management.jmxremote.port=6007 \
    -Dcom.sun.management.jmxremote.authenticate=false \
    -Dcom.sun.management.jmxremote.ssl=false \
    -Djava.library.path=/jilter/xgemail-jilter-${DIRECTION}-${JILTER_VERSION}/lib \
    -Dconf.dir=/data/conf/${DIRECTION} \
    -Dspring.profiles.active=sandbox \
    -Djilter.host=${IPADDRESS} \
    -Xms256m -Xmx256m \
    -cp "/jilter/xgemail-jilter-${DIRECTION}-${JILTER_VERSION}/lib/*" \
    com.sophos.xgemail.jilter.${APPLICATION}Application