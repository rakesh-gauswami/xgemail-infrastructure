#!/bin/bash
#
# This is a utility script to monitor CPU percentage utilization of java processes
# for a period and log the java stack trace of the threads of the process to a file
# 
# Author: Daniel Kwasi Yeboah-Kordieh
# Copyright: Copyright (c) 1997-2018. All rights reserved.
# Company: Sophos Limited or one of its affiliates.

pushd "/tmp/"
CPU=($(top -b -n1 | grep 'java' | head -1 | awk '{print $1, $9, $2}'))

user=${CPU[2]}
utilization=${CPU[1]}
pid=${CPU[0]}

if [ $(echo "$utilization > 90 " | bc) -eq 1 ]; then
    echo "cholotelo: DUMP FOR PROCESS ID <$pid> for user <$user> at time <$(date -u)>" >> $1
    echo "$(jstack -F $pid)" >> $1
else
    echo "Nothing to update"
fi

popd




