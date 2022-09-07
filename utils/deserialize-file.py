#!/usr/bin/env python
# -*- encoding: utf-8 -*-
# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Deserializes a gzipped file downloaded from S3. This script is able to
# deserialize a number of different file types, see MAGIC_NUMBERS dictionary.
# Feel free to add any missing file types to that dictionary, if necessary.
#
# Example (run this from ~/g/xgemail-infrastructure/utils):
# python deserialize-file.py \
#     -d bWdjbmFlcDlhcg== \
#     -o file.deserialized
#

import sys
sys.path.append("../cookbooks/sophos-cloud-xgemail/files/default/")

import argparse
import formatterutils
import gziputils
import json
import os
import messageformatter
import metadataformatter
import bulksenderformatter

DEFAULT_FORMATTER = 'default_formatter'
MESSAGE_FORMATTER = 'message_formatter'
METADATA_FORMATTER = 'metadata_formatter'
BULKSENDER_FORMATTER = 'bulksender_formatter'

MAGIC_NUMBERS = {
    b'\0SOPHCONFIG' : DEFAULT_FORMATTER,
    b'\0SOPHHEDR' : DEFAULT_FORMATTER,
    b'\0SOPHMETA' : METADATA_FORMATTER,
    b'\0SOPHMSG' : MESSAGE_FORMATTER,
    b'\0SOPHPOLCY' : DEFAULT_FORMATTER,
    b'\0SOPHRCPT' : DEFAULT_FORMATTER,
    b'\0SOPHSCAN' : DEFAULT_FORMATTER,
    b'\0SOPHSCDT' : DEFAULT_FORMATTER,
    b'\0SOPHSCDT' : DEFAULT_FORMATTER,
    b'\0SOPHSTAT' : DEFAULT_FORMATTER,
    b'\0SOPHACTRSN' : DEFAULT_FORMATTER,
    b'\0SOPHDLPSMRY' : DEFAULT_FORMATTER,
    b'\0SOPHDLPDTL' : DEFAULT_FORMATTER,
    b'\0SOPHIMPREVNT' : DEFAULT_FORMATTER,
    b'\0SOPHCLKEVT' : DEFAULT_FORMATTER,
    b'\0SOPHBSNDR' : BULKSENDER_FORMATTER,
    b'\0SOPHDASETTINGS' : DEFAULT_FORMATTER,
    b'\0SOPHQACTN' : DEFAULT_FORMATTER,
    b'\0SOPHDLPSDT' : DEFAULT_FORMATTER
}

def is_valid_format(magic_bytes, magic_number):
    """
        Confirms that the provided file is of the correct file format
    """
    return formatterutils.is_correct_file_format(
        magic_bytes,
        magic_number
    )

def get_binary(formatted_file, magic_number):
    """
        Verifies that the magic number matches, decompresses the file and
        returns the content as a string
    """
    magic_number_length = len(magic_number)
    nonce_length_start_idx = 8 + magic_number_length
    nonce_length_end_idx = 12 + magic_number_length

    if not is_valid_format(formatted_file[0:len(magic_number)], magic_number):
        raise ValueError("File format error: invalid magic bytes!")

    if not formatterutils.is_unencypted_data(formatted_file[nonce_length_start_idx:nonce_length_end_idx]):
        raise ValueError("File format error: invalid nonce length bytes!")

    return formatterutils.get_decompressed_object_bytes(
        formatted_file[nonce_length_end_idx:len(formatted_file)]
    )

def print_decoded_json(deserialized_content):
    """
        Prety-prints the deserialized content
    """
    json_content = json.loads(deserialized_content)
    print json.dumps(json_content, indent=4, sort_keys=True)

def deserialize(file_path, output_file_path, magic_number, formatter):
    """
        Responsible for deserializing the provided file
    """
    if not output_file_path:
        output_file_path = '{0}.deserialized'.format(file_path)

    with open(file_path, 'r') as the_file:
        if formatter == DEFAULT_FORMATTER:
            deserialized_content = get_binary(the_file.read(), magic_number)
            print_decoded_json(deserialized_content)
        elif formatter == MESSAGE_FORMATTER:
            deserialized_content = messageformatter.get_message_binary(the_file.read())
        elif formatter == METADATA_FORMATTER:
            deserialized_content = metadataformatter.get_metadata_binary(the_file.read())
            print_decoded_json(deserialized_content)
        elif formatter == BULKSENDER_FORMATTER:
            deserialized_content = bulksenderformatter.get_bulk_sender_binary(the_file.read())
            print_decoded_json(deserialized_content)
        with open(output_file_path, 'w') as output_file:
            output_file.write(deserialized_content)
        print 'Deserialized file <{0}> using magic number <{1}> to <{2}>'.format(file_path, magic_number, output_file_path)

if __name__ == '__main__':
    """
        Main entry point to the script.
    """
    parser = argparse.ArgumentParser(description = 'Deserialize local policy file')
    parser.add_argument('-d', dest='path_to_file', help = 'deserialize the provided policy file')
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

    deserialization_successful = False
    for magic_number, formatter in MAGIC_NUMBERS.iteritems():
        try:
            deserialize(path_to_file, output_file, magic_number, formatter)
            deserialization_successful = True
            break
        except:
            # wrong magic_number, continue trying others
            pass
    if not deserialization_successful:
        print 'ERROR: unable to deserialize file with any of the following magic numbers: {0}'.format(MAGIC_NUMBERS.keys())
