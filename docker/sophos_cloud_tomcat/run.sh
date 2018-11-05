#!/bin/sh
mkdir -p /usr/local/tomcat/temp/amazon-kinesis-producer-native-binaries
ln -s /lib/libc.musl-x86_64.so.1 /usr/local/tomcat/temp/amazon-kinesis-producer-native-binaries/
ln -s /usr/lib/libgcc_s.so.1 /usr/local/tomcat/temp/amazon-kinesis-producer-native-binaries/
ln -s /usr/lib/libidn.so.11 /usr/local/tomcat/temp/amazon-kinesis-producer-native-binaries/
ln -s /lib/libuuid.so.1 /usr/local/tomcat/temp/amazon-kinesis-producer-native-binaries/

/usr/local/tomcat/bin/catalina.sh run
