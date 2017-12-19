#!/usr/bin/env python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import json
import argparse
import logging
import os
import pwd


from ruamel.yaml import round_trip_dump
from ruamel.yaml.util import load_yaml_guess_indent
from ruamel import yaml
from string import Template


def parse_command_line():
    parser = argparse.ArgumentParser(description=" ")
    parser.add_argument("--log_level", "-L", default='INFO',
                        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
                        help="A log level for the python logger")
    parser.add_argument("--template-path", "-P", default='test/kitchen', help="Path all the kitchen templates will be found in")
    parser.add_argument("--templates", "-T", required=True,
                        help="Comma Separated list of templates")
    parser.add_argument("--key-pair", "-K", default='bamboo-agent-key',
                        help="Suite Templates (comma separated)")

    return parser.parse_args()


def setup_template_parameters(args):
    return {
        'KEYPAIR' : args.key_pair
    }


def update_config(config, crumbs, path):
    crumb = crumbs.pop(0)
    if len(crumbs) > 0:

        try:
            if crumb not in config:
                config[crumb] = {}
            config[crumb] = update_config(config[crumb],crumbs, os.path.join(path,crumb))
        except TypeError as e:
            logging.info(config)
            if crumb not in config[0]:
                config[0][crumb] = {}
            config[0][crumb] = update_config(config[0][crumb],crumbs, os.path.join(path,crumb))
        return config
    else:
        with open(os.path.join(path,crumb)) as f:
             return yaml.load(f)



def combine_templates(path,templates):

    config = {"provisioner" : {"name" : "chef_zero"}}
    for template in templates.split(','):

        config = update_config(config, template.split('/'), path)

        # logging.info(config)

    return config



def setup_logging(args):
    # Setup logging
    numeric_level = getattr(logging, args.log_level.upper(), None)
    logging.basicConfig(format='%(asctime)s [%(levelname)s] %(message)s', level=numeric_level)
    logging.debug("Command line arguments are (%s)", args)

# Adds tags to EC2 instance in AWS
# Example EC2 Name: "TestKitchen::danjellesma"
def add_tags_to_config(config):
    kitchen_tags = {
        'tags':
            {
                'created_by': 'test-kitchen',
                'owner': pwd.getpwuid(os.getuid()).pw_name,
                'Name': 'TestKitchen::%s' % (pwd.getpwuid(os.getuid()).pw_name)
            }
    }
    config["driver"].update(kitchen_tags)
    return config

if __name__ == "__main__":
    args = parse_command_line()
    setup_logging(args)
    template_parameters = setup_template_parameters(args)

    config = combine_templates(args.template_path,args.templates)

    try:
        config = add_tags_to_config(config)
    except:
        logging.exception('Problem adding tags to config')
        raise

    with open('.kitchen.yml', 'w') as f:
        yaml_config = yaml.dump(config, indent=4, block_seq_indent=2, Dumper=yaml.RoundTripDumper)
        f.write(Template(yaml_config).safe_substitute(template_parameters))
