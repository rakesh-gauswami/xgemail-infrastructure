#!/usr/bin/env python
# -*- encoding: utf-8 -*-
# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Deserializes a .MESSAGE file downloaded from S3.
# 
# Example:
# python deserialize-message.py -d 172.21.1.225-42kYcL3PQWz1S-invesakk.com.MESSAGE -o message.deserialized
#

import sys
sys.path.append("../../cookbooks/sophos-cloud-xgemail/files/default/")

import argparse
import formatterutils
import gziputils
import json
import messageformatter
import os

def deserialize(file_path, output_file_path):
    if not output_file_path:
        output_file_path = '{0}.deserialized'.format(file_path)

    with open(file_path, 'r') as the_file:
        deserialized_content = messageformatter.get_message_binary(the_file.read())
        with open(output_file_path, 'w') as output_file:
            output_file.write(deserialized_content)

    print 'Deserialized file {0} to {1}'.format(file_path, output_file_path)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description = 'Deserialize local .MESSAGE file')
    parser.add_argument('-d', dest='path_to_file', help = 'deserialize the provided .MESSAGE file')
    parser.add_argument('-o', dest='output_file', help = 'the deserialized output file')

    args = parser.parse_args()
    path = os.getcwd()

    path_to_file = args.path_to_file
    output_file = args.output_file

    if not path_to_file:
        parser.print_help(sys.stderr)
        sys.exit(1)

    if not os.path.isfile(path_to_file):
        print 'File {0} does not exit'.format(path_to_file)
        sys.exit(1)

    deserialize(path_to_file, output_file)
