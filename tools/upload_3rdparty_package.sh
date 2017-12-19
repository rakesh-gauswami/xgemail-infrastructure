#!/bin/bash
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=sh

# upload_3rdparty_package.sh:
#   Bamboo script for downloading a package and uploading it to S3.

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# Fail fast and loud.
set -o xtrace   # Print commands and their arguments as they are executed.
set -o errexit  # Exit immediately if a command exits with a non-zero status.
set -o nounset  # Treat unset variables as an error when substituting.
set -o pipefail # Pipeline status comes from last error, not last command.

# Export AWS credentials for use by subprocesses.
export AWS_ACCESS_KEY_ID="$bamboo_custom_aws_accessKeyId"
export AWS_SECRET_ACCESS_KEY="$bamboo_custom_aws_secretAccessKey_password"
export AWS_SESSION_TOKEN="$bamboo_custom_aws_sessionToken_password"

# TODO: Don't download anything if the package is already in S3.

# TODO: Generate and upload a checksum file that can be used to verify
# file integrity by downloaders.

# Create package file.
tools/create_3rdparty_package.py \
    -s package.txt \
    "${bamboo_PACKAGE}" "${bamboo_VERSION}" "${bamboo_PACKAGE_USERNAME}" "${bamboo_PACKAGE_PASSWORD}"

# Read package file into environment variable.
. ./package.txt

# Bamboo doesn't have s3:GetBucketLocation for the hmr-core account,
# so we have to specify the region explicitly.
tools/upload_to_s3.py \
    "${bamboo_REGION}" "${bamboo_BUCKET}" "${bamboo_FOLDER}" "${PackageFile}"
