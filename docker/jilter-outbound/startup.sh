#!/bin/bash

#Expand the tar file
tar -xvf /jilter/xgemail-jilter-outbound-${JILTER_VERSION}.tar

sleep 5

exec $JAVA_HOME/bin/java \
    -Dcom.sun.management.jmxremote.port=6007 \
    -Dcom.sun.management.jmxremote.authenticate=false \
    -Dcom.sun.management.jmxremote.ssl=false \
    -Djava.library.path=/jilter/xgemail-jilter-outbound-${JILTER_VERSION}/lib \
    -Dconf.dir=/data/conf \
    -Dspring.profiles.active=sandbox \
    -Xms256m \
    -Xmx256m \
    -cp "/jilter/xgemail-jilter-outbound-${JILTER_VERSION}/lib/*" \
    com.sophos.xgemail.jilter.OutboundApplication