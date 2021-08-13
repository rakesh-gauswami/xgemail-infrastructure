#!/usr/bin/env bash
# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

instance_type=`echo $INSTANCE_TYPE`
  if [[ "$instance_type" == jilter-inbound ]]; then
    cd /opt/sophos/xgemail/cookbooks
    chef-client --local-mode -o "recipe[sophos-cloud-xgemail::install_jilter_inbound]"
    /opt/sophos/xgemail/xgemail-jilter-inbound/scripts/xgemail.jilter.service.sh > /dev/null 2>&1
  elif [[ "$instance_type" == jilter-outbound ]]; then
    cd /opt/sophos/xgemail/cookbooks
    chef-client --local-mode -o "recipe[sophos-cloud-xgemail::install_jilter_outbound]"
    /opt/sophos/xgemail/xgemail-jilter-outbound/scripts/xgemail.jilter.service.sh > /dev/null 2>&1
  elif [[ "$instance_type" == mf-jilter-inbound ]]; then
    cd /opt/sophos/xgemail/cookbooks
    chef-client --local-mode -o "recipe[sophos-cloud-xgemail::install_jilter_mf_inbound]"
    /opt/sophos/xgemail/xgemail-jilter-mf-inbound/scripts/xgemail.jilter.service.sh > /dev/null 2>&1
  elif [[ "$instance_type" == mf-jilter-outbound ]]; then
    cd /opt/sophos/xgemail/cookbooks
    chef-client --local-mode -o "recipe[sophos-cloud-xgemail::install_jilter_mf_outbound]"
    /opt/sophos/xgemail/xgemail-jilter-mf-outbound/scripts/xgemail.jilter.service.sh > /dev/null 2>&1
  else
    echo "Incorrect instance type $INSTANCE_TYPE"
  fi