#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Extract destination metadata for injection into a Bamboo namespace.

Extract ACCOUNT, REGION, VPC_NAME, and maybe APPLICATION_NAME from the
branch plan name found in the environment variable bamboo_shortPlanName.
This variable must have the format

    <branch>_<account>_<region>_<vpc_name>_<application>

e.g.

    feature-CPLAT-12345

or

    feature-CPLAT-12345_inf_us-west-2_CloudStation

or

    feature-CPLAT-12345_inf_us-west-2_CloudStation_mcs

The expected number of fields is determined by the --expected-field-count
option.

Derive additional variables:

* VPC_NAME_LOWER_CASE, which is what you expect.

* FALLBACK_BRANCH_PATTERN, which is used to search for dependent
  resources, typically AMIs, if they are not available from the
  repository branch.  The value will either be "release/*" or
  "develop".

* CONNECTOR_ENV, which is used to tell Bamboo which AWS connection
  object to use.

  NOTE! If this program is run on newboo it will set CONNECTOR_ENV
  to the value of CONNECTOR_ENV_NEWBOO.

Print the variable assignments, one per line, so they can be read
by the Inject Bamboo Variables task.

Finally, compare the branch and account variables and fail if we
are not allowed to deploy the specified branch to the specified
account
"""

import optparse
import os
import re
import subprocess
import sys

try:
    import sophos.central
except ImportError as e:
    print >> sys.stderr, e
    print >> sys.stderr, "Wrap this command with bamboo/pywrap.py to update PYTHONPATH."


def parse_command_line():
    parser = optparse.OptionParser(usage="%prog [options]")

    parser.add_option(
            "-e", "--expected-field-count", metavar="NUM", type=int, default=None,
            help="Number expected fields in bamboo shortPlanName variable")

    options, args = parser.parse_args()

    if len(args) > 0:
        parser.error("too many arguments")

    return options


def _die(message):
    sys.stderr.write(sys.argv[0])
    sys.stderr.write(": ")
    sys.stderr.write(message)
    sys.stderr.write("\n")
    sys.exit(1)


def _getenv(key):
    value = os.environ.get(key)
    if value is None:
        _die("missing required environment value '%s'" % key)
    return value


def get_variables(expected_field_count):
    """
    Return the dict of variable assignment to inject into Bamboo.
    """

    variables = {}

    # Retrieve account, region, and VPC from the branch name.

    plan_name = _getenv("bamboo_shortPlanName")

    metadata = plan_name.split("_")

    metadata_field_count = len(metadata)

    if expected_field_count is not None and metadata_field_count != expected_field_count:
        possible_fields = ["<branch>", "<account>", "<region>", "<vpcname>", "<app>"]
        expected_fields = possible_fields[0:expected_field_count]
        expected_format = "_".join(expected_fields)
        _die("branch display name '%s' does not have format '%s'" % (plan_name, expected_format))

    if metadata_field_count > 1:
        variables["ACCOUNT"] = metadata[1]

        # Find the hopper associated with the account.

        hopper_account = "dev"
        hopper_host = "hopper-dev.cloud.sophos"

        if variables["ACCOUNT"] in sophos.central.prod_accounts_list():
            hopper_account = variables["ACCOUNT"]
            hopper_host = "hopper-%s.cloud.sophos" % variables["ACCOUNT"]

        variables["HOPPER_ACCOUNT"] = hopper_account
        variables["HOPPER_HOST"] = hopper_host

        # Find the connector variable to use for the account extracted from
        # the branch name.

        # Assume we will always be called from within a git repository.

        repo_path = subprocess.check_output("git rev-parse --show-toplevel".split()).strip()

        connector_parameters = [
            "CONNECTOR_ENV",
            "CONNECTOR_ENV_NEWBOO",
        ]

        connector_parameters += ["HOPPER_" + p for p in connector_parameters]

        for connector_parameter in connector_parameters:
            # The account and parameter we look for may be different for the hopper,
            # since one hopper is shared by all non-production accounts.
            account = variables["ACCOUNT"]
            parameter = connector_parameter
            if connector_parameter.startswith("HOPPER_"):
                account = hopper_account
                parameter = parameter[7:]

            command = [
                os.path.join(repo_path, "ww/variable-wizard.py"),
                "--command", "GET",
                "--parameter", parameter,
                "--env", account,
            ]

            process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            process.wait()

            if process.returncode != 0:
                _die("cannot find connector variable '%s' for account '%s'" % (
                    parameter,
                    account))

            output = process.stdout.read().strip()

            variables[connector_parameter] = output.split("=")[-1]

    if metadata_field_count > 2:
        variables["REGION"] = metadata[2]

    if metadata_field_count > 3:
        variables["VPC_NAME"] = metadata[3]
        variables["VPC_NAME_LOWER_CASE"] = variables["VPC_NAME"].lower()

    if metadata_field_count > 4:
        variables["APPLICATION"] = metadata[4]

    # Determine fallback branch search pattern to use for dependent resources
    # (typically AMIs) if they are not available from the repository branch.
    # Note that this is a branch pattern; we assume whatever code uses it is
    # smart enough to handle multiple matches and do the right thing.

    bamboo_branch = _getenv("bamboo_planRepository_branchName")

    variables["FALLBACK_BRANCH_PATTERN"] = "release/*"
    if bamboo_branch.startswith(("develop", "feature")):
        variables["FALLBACK_BRANCH_PATTERN"] = "develop"

    return variables

def _main():
    options = parse_command_line()
    variables = get_variables(options.expected_field_count)

    # Is this deployment allowed?
    permitted = False
    branch = os.environ.get("bamboo_repository_branch_name")
    account = None
    region = None
    if branch is not None:
        account = variables.get("ACCOUNT")
        if account is not None:
            # If region is specified it must be supported.  Region might
            # not be specified, so we have to accommodate that too.
            region = variables.get("REGION")
            if region is None or region in sophos.central.supported_regions_list():
                permitted = sophos.central.can_deploy_branch(branch, account)

    # We want the deployment to fail if it is not allowed, but exiting
    # with a non-zero status from this program may not be enough to cause
    # the failure.  There are a couple ways things could go wrong:
    #
    # First, this program may be called in a UNIX pipeline that discards
    # the exit code of all but the last program in the pipe.  If the shell
    # option pipefail is not set then the pipeline can succeed even if one
    # of the programs in the pipeline fails.
    #
    # Second, another program may be called after this one, for example
    # to cat the output file.  If the shell option errexit is not set then
    # the fact that this program fails will not preclude execution of a
    # subsequent program that masks this program's failure.
    #
    # To guard against the exit code being ignored we will modify the
    # variable assignment output to make it unusable when deployment is
    # not allowed.

    leader = ""
    header = None
    if not permitted:
        leader = "# "
        header = "Deployment of branch '%s' to account '%s' region '%s' is NOT permitted." % (branch, account, region)
        print >> sys.stderr, header

    items = sorted(variables.items())
    if header is not None:
        print "%s%s" % (leader, header)
    for k, v in items:
        print "%s%s=%s" % (leader, k, v)

    if not permitted:
        sys.exit(1)

if __name__ == "__main__":
    _main()
