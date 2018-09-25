#!/bin/bash

export IPADDRESS=`hostname -i`

#Expand the tar file
tar -xvf /jilter/xgemail-jilter-inbound-${JILTER_VERSION}.tar

#Start the jilter service
exec $JAVA_HOME/bin/java \
    -Dcom.sun.management.jmxremote.port=6007 \
    -Dcom.sun.management.jmxremote.authenticate=false \
    -Dcom.sun.management.jmxremote.ssl=false \
    -Djava.library.path=/jilter/xgemail-jilter-inbound-${JILTER_VERSION}/lib \
    -Dconf.dir=/data/conf \
    -Dspring.profiles.active=sandbox \
    -Djilter.host=${IPADDRESS} \
    -Xms256m -Xmx256m \
    -cp "/jilter/xgemail-jilter-inbound-${JILTER_VERSION}/lib/*" \
    com.sophos.xgemail.jilter.Application