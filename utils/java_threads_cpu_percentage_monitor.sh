#!/bin/bash
#
# This is a utility script to determine the process using the most cpu resources
# where that process is using more than 90% cpu.

# If that process is a java process,
# the java stack trace of the threads of the process are logged to a file.
# In addition, this logs the 5 most active threads of the java process,
# their pids, how long they have been up and what percentage of cpu
# they are using.
#
# usage: $ bash java_threads_cpu_percentage_monitor.sh <output_file>
#
# Author: Daniel Kwasi Yeboah-Kordieh
# Copyright: Copyright (c) 1997-2018. All rights reserved.
# Company: Sophos Limited or one of its affiliates.

pushd "/tmp/"
CPU=($(top -b -n1 | head -8 | tail -1 | awk '{print $1, $9, $2, $11, $12}'))

user=${CPU[2]}
utilization=${CPU[1]}
pid=${CPU[0]}
time=${CPU[3]}
command=${CPU[4]}

if [ $(echo "$utilization > 90 " | bc) -eq 1 ]; then
    echo "PROCESS_LOG: Command <$command> with PROCESS ID <$pid> for user <$user> at time <$(date -u)> used cpu <$utilization> and has been up for <$time>" >> $1
    if [ $command == "java" ]; then
      threads=($(top -b -n1 -H | grep 'java' | head -5 | awk '{print $1, $9, $11}'))
      echo "$(jstack -F $pid)" >> $1

      t1_id=${threads[0]}
      t1_usage=${threads[1]}
      t1_time_up=${threads[2]}

      t2_id=${threads[3]}
      t2_usage=${threads[4]}
      t2_time_up=${threads[5]}

      t3_id=${threads[6]}
      t3_usage=${threads[7]}
      t3_time_up=${threads[8]}

      t4_id=${threads[9]}
      t4_usage=${threads[10]}
      t4_time_up=${threads[11]}

      t5_id=${threads[12]}
      t5_usage=${threads[13]}
      t5_time_up=${threads[14]}

      echo "THREAD_LOG: $pid: Most active thread had pid <$t1_id> with usage <$t1_usage> running for <$t1_time_up>" >> $1
      echo "THREAD_LOG: $pid: 2nd Most active thread had pid <$t2_id> with usage <$t2_usage> running for <$t2_time_up>" >> $1
      echo "THREAD_LOG: $pid: 3rd Most active thread had pid <$t3_id> with usage <$t3_usage> running for <$t3_time_up>" >> $1
      echo "THREAD_LOG: $pid: 4th Most active thread had pid <$t4_id> with usage <$t4_usage> running for <$t4_time_up>" >> $1
      echo "THREAD_LOG: $pid: 5th Most active thread had pid <$t5_id> with usage <$t5_usage> running for <$t5_time_up>" >> $1
    fi



else
    echo "Nothing to update"
fi

popd
