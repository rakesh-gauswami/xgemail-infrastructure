#!/usr/bin/env python3
# vim: autoindent expandtab shiftwidth=4 filetype=python

"""
Create missing Jenkins files for all PoP account/pipeline combinations.

Example:
    %(prog)s cicd/pipelines
"""

import argparse
import os
import signal

import supported_environment

CRON = True
NO_CRON = False

PIPELINES = [
    # pipeline_name, pipeline_function
    ('xgemail-infrastructure-ci',       'xgemailInfrastructureCIPipeline',    NO_CRON),
    ('xgemail-infrastructure',          'xgemailInfrastructureDeployPipeline',   CRON),
    ('internet-submit-deploy',          'internetSubmitDeployPipeline',          CRON),
    ('customer-delivery-deploy',        'customerDeliveryDeployPipeline',        CRON),
    ('customer-xdelivery-deploy',       'customerXdeliveryDeployPipeline',       CRON),
    ('customer-submit-deploy',          'customerSubmitDeployPipeline',          CRON),
    ('internet-delivery-deploy',        'internetDeliveryDeployPipeline',        CRON),
    ('internet-xdelivery-deploy',       'internetXdeliveryDeployPipeline',       CRON),
    ('risky-delivery-deploy',           'riskyDeliveryDeployPipeline',           CRON),
    ('risky-xdelivery-deploy',          'riskyXdeliveryDeployPipeline',          CRON),
    ('warmup-delivery-deploy',          'warmupDeliveryDeployPipeline',          CRON),
    ('warmup-xdelivery-deploy',         'warmupXdeliveryDeployPipeline',         CRON),
    ('delta-delivery-deploy',           'deltaDeliveryDeployPipeline',           CRON),
    ('delta-xdelivery-deploy',          'deltaXdeliveryDeployPipeline',          CRON),
    ('encryption-submit-deploy',        'encryptionSubmitDeployPipeline',        CRON),
    ('encryption-delivery-deploy',      'encryptionDeliveryDeployPipeline',      CRON),
    ('mfr-inbound-submit-deploy',       'mfrInboundSubmitDeployPipeline',        CRON),
    ('mfr-inbound-delivery-deploy',     'mfrInboundDeliveryDeployPipeline',      CRON),
    ('mfr-inbound-xdelivery-deploy',    'mfrInboundXdeliveryDeployPipeline',     CRON),
    ('mfr-outbound-submit-deploy',      'mfrOutboundSubmitDeployPipeline',       CRON),
    ('mfr-outbound-delivery-deploy',    'mfrOutboundDeliveryDeployPipeline',     CRON),
    ('mfr-outbound-xdelivery-deploy',   'mfrOutboundXdeliveryDeployPipeline',    CRON)
]

CRON_MINUTE_OFFSETS = {
    'inf' : 'H(15-24)',
    'dev' : 'H(0-9)',
    'qa'  : 'H(0-9)'
}

CRON_SETTINGS_FORMAT = "\n    cronExpression = '{cron_expression}'"

CRON_SPEC_FORMAT = '{} 4,8,12,16,23 * * 0-5'

JENKINSFILE_FORMAT = """
// vim: autoindent expandtab shiftwidth=4 filetype=groovy
// This file was originally generated by bamboo/create-pop-jenkins-files.py

@Library('msg/msg-jenkins')
@Library('devops/sophos-jenkins-shared-library')
_

{function} {{
    accountName = '{account_name}'{cron_settings}
}}
""".strip()

def main():
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    args = parse_command_line()
    process(args)

def parse_command_line():
    doclines = __doc__.strip().splitlines()
    description = doclines[0]
    epilog = ("\n".join(doclines[1:])).strip()

    parser = argparse.ArgumentParser(
            description=description,
            epilog=epilog,
            formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
            "-f", "--force",
            action='store_true',
            help="forcibly recreate ALL Jenkins files, even if they already exist")

    parser.add_argument(
            "dir",
            help="create Jenkins files under this directory.")

    return parser.parse_args()

def process(args):
    skipped = 0
    created = 0

    print("creating files relative to", os.path.abspath(args.dir))
    print()

    account_names = supported_environment.SUPPORTED_ENVIRONMENT.get_pop_account_names()

    for account_name in account_names:
        account = supported_environment.SUPPORTED_ENVIRONMENT.get_pop_account(account_name)
        subdir = "{}-{}".format(account.get_deployment_environment(), account_name)

        for pipeline_name, pipeline_function, is_on_cron in PIPELINES:
            path = os.path.join(args.dir, subdir, pipeline_name, 'Jenkinsfile')

            if is_on_cron:
                if account.deployment_environment in ['perf', 'prod']:
                    cron_expression = ''
                else:
                    cron_expression = CRON_SPEC_FORMAT.format(CRON_MINUTE_OFFSETS[account.deployment_environment])

                cron_settings = CRON_SETTINGS_FORMAT.format(
                    cron_expression = cron_expression
                )
            else:
                cron_settings = ''

            if not args.force and os.path.exists(path):
                print("skipping", path, "(it already exists)")
                skipped += 1
                continue

            print("creating", path, "...")
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                print(JENKINSFILE_FORMAT.format(
                    function      = pipeline_function,
                    account_name  = account_name,
                    cron_settings = cron_settings
                ), file=f)
            created += 1

    print()
    print("skipped", skipped, "file(s)")
    print("created", created, "file(s)")

if __name__ == "__main__":
    main()
