#!/usr/bin/env bash
# vim: autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

instance_type=`echo $INSTANCE_TYPE`
  if [[ "$instance_type" == customer-delivery ||  "$instance_type" == internet-delivery ]]; then
    echo "################ Stage container using postfix image ###################"
    cd /opt/sophos/xgemail/cookbooks
    chef-client --local-mode -o "recipe[sophos-cloud-xgemail::configure-postfix]"
    echo "################ Installing fluentd ###################"
    chef-client --local-mode -o "recipe[sophos-msg-fluentd::install]"
    echo "################ Fluentd installation is complete ###################"
  elif [[ "$instance_type" == customer-submit ||  "$instance_type" == internet-submit ]]; then
    echo "################ Stage container using postfix image ###################"
    cd /opt/sophos/xgemail/cookbooks
    chef-client --local-mode -o "recipe[sophos-cloud-xgemail::configure-postfix]"
  else
    echo "Incorrect instance type $INSTANCE_TYPE"
  fi
