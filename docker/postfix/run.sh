#!/usr/bin/env bash
# vim: autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

echo "################ Stage container using postfix image ###################"
cd /opt/sophos/xgemail/cookbooks
chef-client --local-mode -o "recipe[sophos-cloud-xgemail::configure-postfix]"

