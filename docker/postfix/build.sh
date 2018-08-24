#!/usr/bin/env bash
# vim: autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

echo "################ Building postix ###################"

THIRD_PATRY=~/g/email/thirdparty
POSTFIX_SOPHOS_PATH=postfix3-sophos/output
POSTFIX_SOPHOS_RPM=postfix3-sophos-3.2.4.1-1.el7.x86_64.rpm

postfix_rpm=${THIRD_PATRY}/${POSTFIX_SOPHOS_PATH}/${POSTFIX_SOPHOS_RPM}

if [ ! -f ${postfix_rpm} ]; then
    echo "POSFIX-SOHPOS RPM is not found! Can't build the image."
else
    mkdir thirdparty
    cp ${postfix_rpm} thirdparty
    docker build -t postfix .
    docker images postfix
fi
