#!/bin/bash
#
# Script to prepare database instances for POSTFIX to query 
# for restrictions applied on incoming email traffic.
#
MAP_PATH=`dirname $(realpath $0)`

postmap $MAP_PATH/rbl_reply_maps
postmap $MAP_PATH/recipient_access
postmap $MAP_PATH/relay_domains
postmap $MAP_PATH/soft_retry_senders_map
