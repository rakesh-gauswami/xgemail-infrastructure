#!/bin/bash
#
# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
#   Deletes aged elasticsearch logs
#

set -eu

ES_LOG_DIR='<%= @elasticsearch_log_dir %>'
ES_LOG_RETENTION_DAYS='<%= @elasticsearch_log_retention_days %>'

find "${ES_LOG_DIR}" \
  -regextype posix-extended \
  -regex '.*\.log\.[0-9]{4}-[0-9]{2}-[0-9]{2}$' \
  -mtime "+${ES_LOG_RETENTION_DAYS}" \
  -printf 'Deleting aged elasticsearch log file <%p>\n' \
  -delete
