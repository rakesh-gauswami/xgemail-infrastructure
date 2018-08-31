#!/bin/bash
#
# Script to prepare database instances for POSTFIX to query 
# for restrictions applied on incoming email traffic.
#
postmap rbl_reply_maps
postmap recipient_access
postmap relay_domains
postmap soft_retry_senders_map
