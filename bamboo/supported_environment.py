# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Describes AWS environments
"""

import re
import uuid

from abc import ABC

ACTIVE_ACCOUNT = True
DISABLED_ACCOUNT = False

REGION_AP_NORTHEAST_1   = 'ap-northeast-1'
REGION_AP_SOUTH_1       = 'ap-south-1'
REGION_AP_SOUTHEAST_2   = 'ap-southeast-2'
REGION_CA_CENTRAL_1     = 'ca-central-1'
REGION_EU_CENTRAL_1     = 'eu-central-1'
REGION_EU_WEST_1        = 'eu-west-1'
REGION_SA_EAST_1        = 'sa-east-1'
REGION_US_EAST_1        = 'us-east-1'
REGION_US_EAST_2        = 'us-east-2'
REGION_US_WEST_2        = 'us-west-2'

DEPLOYMENT_ENVIRONMENT_DEV  = 'dev'
DEPLOYMENT_ENVIRONMENT_INF  = 'inf'
DEPLOYMENT_ENVIRONMENT_PERF = 'perf'
DEPLOYMENT_ENVIRONMENT_PROD = 'prod'
DEPLOYMENT_ENVIRONMENT_QA   = 'qa'

AWS_CONNECTORS = {
    'hammer-core/CloudBuilder' : '{d021e988-7b8d-4d13-9f7d-1580a0169b5e}',
    'hammer-core/CloudDeployer' : '{53328c30-ce73-402b-a240-e572c2733e49}',
    'hammer-core/CloudDeployer-dev' : '{6ba78f8d-c3b5-46e6-944d-ea9376c3bdb7}',
    'hammer-core/CloudDeployer-dev3' : '{7f6e8324-e4b5-4943-ac6b-dd5f27738a3d}',
    'hammer-core/CloudDeployer-inf' : '{45ad1c14-edde-48a1-a36c-e3e7c986998a}',
    'hammer-core/packer' : '{a21d9502-28e7-4dc3-8455-8bf25bfb7b7d}',
    'hammer-core/SophosAPFirmware' : '{54d9c157-10b0-4557-8de0-cf9ab341f390}',
    'hammer-dev4/CloudDeployer-dev4' : '{eeb80308-cd54-4686-9b74-62bffc4a657e}',
    'hammer-mr/CloudDeployer-mr' : '{df18bb5f-7c26-4838-9048-3b5c6e034439}',
    'hammer-prod/CloudDeployer' : '{80b04967-1fe3-481f-a22a-fb7f99f615b5}',
    'hammer-qa/CloudDeployer-QA' : '{3d547301-2d95-459a-bd50-fcad86b65c03}',
}

AWS_REGIONS = [
    REGION_AP_NORTHEAST_1,
    REGION_AP_SOUTH_1,
    REGION_AP_SOUTHEAST_2,
    REGION_CA_CENTRAL_1,
    REGION_EU_CENTRAL_1,
    REGION_EU_WEST_1,
    REGION_SA_EAST_1,
    REGION_US_EAST_1,
    REGION_US_EAST_2,
    REGION_US_WEST_2
]

REGION_CODES = {
    REGION_AP_NORTHEAST_1: '0901',
    REGION_AP_SOUTH_1: '0531',
    REGION_AP_SOUTHEAST_2: '1001',
    REGION_CA_CENTRAL_1: '1903',
    REGION_EU_CENTRAL_1: '0101',
    REGION_EU_WEST_1: '0001',
    REGION_SA_EAST_1: '2101',
    REGION_US_EAST_1: '1901',
    REGION_US_EAST_2: '1902',
    REGION_US_WEST_2: '1602'
}

REGION_TO_AIRPORT_CODES = {
    # Chattrapathi Shivaji Airport: Mumbai, India
    REGION_AP_SOUTH_1: 'bom',

    # Haneda Airport: Tokyo, Japan
    REGION_AP_NORTHEAST_1: 'hnd',
    # Sydney Airport
    REGION_AP_SOUTHEAST_2: 'syd',

    # Montréal-Trudeau International Airport
    REGION_CA_CENTRAL_1: 'yul',

    # Frankfurt Airport: Frankfurt, Germany
    REGION_EU_CENTRAL_1: 'fra',
    # Dublin Airport: Dublin, Ireland
    REGION_EU_WEST_1: 'dub',

    # São Paulo/Guarulhos-Governador André Franco Montoro International Airport: São Paulo, Brazil
    REGION_SA_EAST_1: 'gru',

    # Dulles International Airport: Dulles, VA, USA
    REGION_US_EAST_1: 'iad',
    # John Glenn Columbus International Airport: Columbus, OH, USA
    REGION_US_EAST_2: 'cmh',
    # Portland International Airport: Boardman, OR, USA
    REGION_US_WEST_2: 'pdx'
}

AIRPORT_TO_REGION_CODES = { value: key for key, value in REGION_TO_AIRPORT_CODES.items() }

POP_ACCOUNT_TYPES = {
    'devops'        : 'ops',
    'email'         : 'eml',
    'home'          : 'hme',
    'hub'           : 'hub',
    'integration'   : 'int',
    'station'       : 'stn'
}

ACCOUNT_ABBREVIATION_TO_FULL_TYPE = { value: key for key, value in POP_ACCOUNT_TYPES.items() }

PREPROD_DEPLOYMENT_ENVIRONMENTS_INDEX = {
    '0': DEPLOYMENT_ENVIRONMENT_INF,
    '1': DEPLOYMENT_ENVIRONMENT_DEV,
    '2': DEPLOYMENT_ENVIRONMENT_PERF,
    '3': DEPLOYMENT_ENVIRONMENT_QA
}

DEPLOYMENT_ENVIRONMENTS = [
    DEPLOYMENT_ENVIRONMENT_DEV,
    DEPLOYMENT_ENVIRONMENT_INF,
    DEPLOYMENT_ENVIRONMENT_PERF,
    DEPLOYMENT_ENVIRONMENT_PROD,
    DEPLOYMENT_ENVIRONMENT_QA
]

RELEASE_ENVIRONMENTS = [
    DEPLOYMENT_ENVIRONMENT_PROD,
    DEPLOYMENT_ENVIRONMENT_QA
]

LEGACY_ACCOUNTS = {
    'core': {
        'id': '843638552935',
        'connector': 'hammer-core/CloudBuilder',
        'active': True,
        'deployment_environment': None,
        'station-regions': [],
        'hub-region': None
    },
    'dev': {
        'id': '750199083801',
        'connector': 'hammer-core/CloudDeployer-dev',
        'active': True,
        'deployment_environment': DEPLOYMENT_ENVIRONMENT_DEV,
        'station-regions': [
            REGION_EU_CENTRAL_1,
            REGION_EU_WEST_1,
            REGION_US_EAST_1
        ],
        'hub-region': REGION_EU_WEST_1
    },
    'dev3': {
        'id': '769208163330',
        'connector': 'hammer-core/CloudDeployer-dev3',
        'active': True,
        'deployment_environment': DEPLOYMENT_ENVIRONMENT_PERF,
        'station-regions': [
            REGION_EU_WEST_1,
            REGION_US_EAST_1,
            REGION_US_WEST_2
        ],
        'hub-region': REGION_EU_WEST_1
    },
    'inf': {
        'id': '283871543274',
        'connector': 'hammer-core/CloudDeployer-inf',
        'active': True,
        'deployment_environment': DEPLOYMENT_ENVIRONMENT_INF,
        'station-regions': [
            REGION_EU_WEST_1,
            REGION_US_EAST_1
        ],
        'hub-region': REGION_EU_WEST_1
    },
    'mr': {
        'id': '125218878894',
        'connector': 'hammer-mr/CloudDeployer-mr',
        'active': True,
        'deployment_environment': DEPLOYMENT_ENVIRONMENT_DEV,
        'station-regions': [
            'us-west-2'
        ],
        'hub-region': None  # No Java instances go here!
    },
    'prod': {
        'id': '202058678495',
        'connector': 'hammer-prod/CloudDeployer',
        'active': True,
        'deployment_environment': DEPLOYMENT_ENVIRONMENT_PROD,
        'station-regions': [
            REGION_EU_CENTRAL_1,
            REGION_EU_WEST_1,
            REGION_US_EAST_1,
            REGION_US_EAST_2,
            REGION_US_WEST_2
        ],
        'hub-region': REGION_EU_WEST_1
    },
    'qa': {
        'id': '382702281923',
        'connector': 'hammer-qa/CloudDeployer-QA',
        'active': True,
        'deployment_environment': DEPLOYMENT_ENVIRONMENT_QA,
        'station-regions': [
            REGION_EU_CENTRAL_1,
            REGION_US_EAST_1,
            REGION_US_WEST_2
        ],
        'hub-region': REGION_EU_WEST_1
    }
}

POP_ACCOUNTS = {
    'eml000cmh': {
        'id': '399066527731'
    },
    'eml010yul': {
        'id': '331664993034'
    },
    'eml030bom': {
        'id': '265385962095'
    },
    'eml030gru': {
        'id': '068701954430'
    },
    'eml030hnd': {
        'id': '143378974272'
    },
    'eml030syd': {
        'id': '267679260514'
    },
    'eml100bom': {
        'id': '390762413450'
    },
    'eml100gru': {
        'id': '022066319197'
    },
    'eml100hnd': {
        'id': '114019105507'
    },
    'eml100syd': {
        'id': '345736415124'
    },
    'eml100yul': {
        'id': '166932968136'
    }
}

CONNECTOR_REGEX = re.compile(r"^\{[0-9a-f\-].*\}$")

POP_ACCOUNT_NAME_REGEX = re.compile(r"^([a-z]{3})(\d{3})([a-z]{3})$")

VALID_RELEASE_BRANCH_REGEX = re.compile(
        r"^release/(CSA-)?20\d\d\.\d\d(-[^ ]+)?$"
    )

VALID_DEVELOPMENT_BRANCH_REGEX = re.compile(
        r"^(feature|bugfix|hotfix)/.+$"
    )

def is_release_environment(environment):
    """
    is_release_environment
    """
    return environment in RELEASE_ENVIRONMENTS

def is_valid_release_branch(branch):
    """
    is_valid_release_branch
    """
    return VALID_RELEASE_BRANCH_REGEX.match(branch) is not None

def is_valid_deployment_environment(environment):
    """
    is_valid_deployment_environment
    """
    return environment in DEPLOYMENT_ENVIRONMENTS


def is_valid_development_branch(branch):
    """
    is_valid_development_branch
    """

    if branch == 'develop':
        return True

    return VALID_DEVELOPMENT_BRANCH_REGEX.match(branch) is not None

def is_valid_branch(branch):
    """
    is_valid_branch
    """
    return is_valid_development_branch(branch) or is_valid_release_branch(branch)

def is_valid_region(region):
    """
    is_valid_region
    """
    return region in AWS_REGIONS


class AwsConnector:
    """
    Describes bamboo's AWS connector
    """
    def __init__(
        self,
        name,
        connector_id
    ):
        self.name = name
        self.connector_id = connector_id

        if not CONNECTOR_REGEX.match(self.connector_id):
            raise ValueError(
                    'Invalid connector id <{}> for <{}>'.format(
                        self.connector_id,
                        self.name
                    )
                )

        try:
            uuid.UUID(self.connector_id)
        except ValueError as ex:
            raise ValueError(
                    'Invalid connector id <{}> for <{}>'.format(
                        self.connector_id,
                        self.name
                    )
                ) from ex

    def __str__(self):
        return '{{{}:{}}}'.format(self.name, self.connector_id)

    def __repr__(self):
        return self.__str__()

class BaseAccountData(ABC): # pylint: disable=too-few-public-methods
    """
    Describes AWS hub account
    """
    def __init__(
        self,
        name,
        account_id,
        is_active,
        deployment_environment
    ):
        self.name = name
        self.account_id = account_id
        self.is_active = is_active
        self.deployment_environment = deployment_environment
        self.is_release_environment = is_release_environment(self.deployment_environment)

        try:
            int(self.account_id)
        except ValueError as ex:
            raise ValueError(
                    'Invalid account id <{}> for account <{}>'.format(
                        self.account_id,
                        self.name
                    )
                ) from ex

        if not isinstance(self.is_active, bool) :
            raise ValueError(
                    'Expecting is_active <{}> to be of bool type for account <{}>'.format(
                        self.is_active,
                        self.name
                    )
                )

    def get_deployment_environment(self):
        """
        get_deployment_environment
        """
        return self.deployment_environment

    def can_deploy_branch(
        self,
        branch
    ):
        """
        can_deploy_branch
        """

        if not self.is_active:
            return False

        if self.is_release_environment:
            return is_valid_release_branch(branch)

        return is_valid_branch(branch)

class LegacyAccountData(BaseAccountData):
    """
    Describes AWS legacy account
    """
    def __init__(
        self,
        name,
        account_id,
        connector,
        is_active,
        deployment_environment,
        station_regions,
        hub_region
    ):
        super().__init__(
            name,
            account_id,
            is_active,
            deployment_environment
        )

        self.connector = connector
        self.station_regions = station_regions
        self.hub_region = hub_region

        for region in self.station_regions:
            if not is_valid_region(region):
                raise ValueError(
                        'Invalid station region <{}> for account <{}>'.format(
                            region,
                            self.name
                        )
                    )

        if len(set(self.station_regions)) != len(self.station_regions):
            raise ValueError(
                    'Duplicate entries in station regions <{}> for account <{}>'.format(
                        self.station_regions,
                        self.name
                    )
                )

        if self.station_regions != sorted(self.station_regions):
            raise ValueError(
                'Please sort station regions entries <{}> for account <{}>'.format(
                    self.station_regions,
                    self.name
                )
            )

        if self.hub_region and not is_valid_region(self.hub_region):
            raise ValueError(
                    'Invalid hub region <{}> for account <{}>'.format(
                        self.hub_region,
                        self.name
                    )
                )

        if self.is_active and not self.connector :
            raise ValueError(
                    'Connector is required for active account <{}>'.format(
                        self.name
                    )
                )

    def __str__(self):
        return '{{{}({}):active({}),env({}),is_release({}),hub({}),stations({})}}'.format(
                self.name,
                self.account_id,
                self.is_active,
                self.deployment_environment,
                self.is_release_environment,
                self.hub_region,
                self.station_regions
            )

    def __repr__(self):
        return self.__str__()

    def get_station_regions(self):
        """
        get_station_regions
        """
        return self.station_regions

class PopAccountData(BaseAccountData):
    """
    Describes PoP account
    """
    def __init__(
        self,
        name,
        account_id,
        deployment_environment,
        account_type,
        primary_region
    ):
        super().__init__(
            name,
            account_id,
            True,
            deployment_environment
        )

        self.account_type = account_type
        self.primary_region = primary_region

    def get_account_id(self):
        """
        get_account_id
        """
        return self.account_id

    def get_account_type(self):
        """
        get_account_type
        """
        return self.account_type

    def get_parent_account_id(self):
        """
        get_parent_account_id
        """
        parent_account_name = self.get_parent_account_name()
        return LEGACY_ACCOUNTS[parent_account_name]['id']

    def get_parent_account_name(self):
        return "dev3" if self.deployment_environment == "perf" else self.deployment_environment

    def get_primary_region(self):
        """
        get_primary_region
        """
        return self.primary_region

    def __str__(self):
        return '{{{}({}):active({}),env({}),is_release({}),account_type({}),region({})}}'.format(
                self.name,
                self.account_id,
                self.is_active,
                self.deployment_environment,
                self.is_release_environment,
                self.account_type,
                self.primary_region
            )

    def __repr__(self):
        return self.__str__()


class SupportedEnvironment:
    """
    Describes all valid accounts
    """
    def __init__(
        self,
        aws_connectors_dict,
        aws_regions,
        region_codes,
        region_to_airport_codes,
        legacy_accounts_dict,
        pop_accounts_dict
    ):
        self.aws_connectors = {
            key: AwsConnector(key, value) for key, value in aws_connectors_dict.items()
        }

        self.aws_regions = aws_regions

        if len(set(self.aws_regions)) != len(self.aws_regions):
            raise ValueError(
                    'Duplicate entries in aws_regions <{}>'.format(
                        self.aws_regions
                    )
                )

        if self.aws_regions != sorted(self.aws_regions):
            raise ValueError(
                    'Please sort aws_regions entries <{}>'.format(
                        self.aws_regions
                    )
                )

        self.region_codes = region_codes

        if set(self.region_codes.keys()) != set(self.aws_regions):
            raise ValueError(
                    'Region codes <{}> do not cover all supported regions <{}>'.format(
                        self.region_codes,
                        self.aws_regions
                    )
                )

        if len(set(self.region_codes.values())) != len(self.aws_regions):
            raise ValueError(
                    'Region codes <{}> have duplicates'.format(
                        str(self.region_codes)
                    )
                )

        self.region_to_airport_codes = region_to_airport_codes

        if set(self.region_to_airport_codes.keys()) != set(self.aws_regions):
            raise ValueError(
                    'Region airport codes <{}> do not cover all supported regions <{}>'.format(
                        self.region_to_airport_codes,
                        self.aws_regions
                    )
                )

        if len(set(self.region_to_airport_codes.values())) != len(self.aws_regions):
            raise ValueError(
                    'Region airport codes <{}> have duplicates'.format(
                        str(self.region_codes)
                    )
                )

        self.legacy_accounts = {}

        for key, value in legacy_accounts_dict.items():
            try:
                connector_str = value['connector']

                if connector_str:
                    try:
                        connector = self.aws_connectors[connector_str]
                    except KeyError as ex:
                        raise ValueError(
                                'Invalid connector string <{}> for account <{}>'.format(
                                    connector_str,
                                    key
                                )
                            ) from ex

                    if not connector:
                        raise ValueError(
                                'Invalid connector for <{}> for account <{}>'.format(
                                    connector_str,
                                    key
                                )
                            )

                self.legacy_accounts[ key ] = LegacyAccountData(
                    key,
                    value['id'],
                    connector,
                    value['active'],
                    value['deployment_environment'],
                    value['station-regions'],
                    value['hub-region']
                )

            except KeyError as ex:
                raise ValueError(
                        'Key <{}> is not found for legacy account <{}>'.format(ex, key)
                    ) from ex

        self.pop_accounts = {
            key: self.create_pop_account_data(
                key,
                value['id']
            ) for key, value in pop_accounts_dict.items()
        }

    def get_account(self, name):
        """
        get_account returns any account that matches name
        """
        ret_val = self.legacy_accounts.get(name)

        if ret_val is not None:
            return ret_val

        ret_val = self.pop_accounts.get(name)

        if ret_val is None:
            raise ValueError(
                    'Unknown account <{}>'.format(name)
                )

        return ret_val

    def get_legacy_account(self, name) :
        """
        get_legacy_account
        """

        ret_val = self.legacy_accounts.get(name)

        if ret_val is None:
            raise ValueError(
                    'Unknown account <{}>'.format(name)
                )

        return ret_val

    def get_legacy_account_names(self) :
        """
        get_legacy_account_names
        """
        return sorted(list(self.legacy_accounts.keys()))

    def get_pop_account(self, name) :
        """
        get_pop_account
        """

        ret_val = self.pop_accounts.get(name)

        if ret_val is None:
            raise ValueError(
                    'Unknown account <{}>'.format(name)
                )

        return ret_val

    def get_pop_account_names(self) :
        """
        get_pop_account_names
        """
        return sorted(list(self.pop_accounts.keys()))

    def get_station_regions(self, account_name) :
        """
        get_station_regions
        """
        account = self.get_legacy_account(account_name)

        return sorted(account.get_station_regions())

    def get_region_code(self, region) :
        """
        get_region_code
        """
        if not is_valid_region(region):
            raise ValueError( 'Invalid region <{}>'.format( region ) )

        return self.region_codes[ region ]

    @staticmethod
    def create_pop_account_data(
            name,
            account_id
        ):
        """
        parse_pop_account_name
        """

        pop_account_matcher = POP_ACCOUNT_NAME_REGEX.match(name)

        if pop_account_matcher is None:
            raise ValueError(
                    'Invalid PoP account name <{}>'.format(
                        name
                    )
                )

        pop_abbreviated_type = pop_account_matcher.group(1)
        account_index = pop_account_matcher.group(2)
        pop_airport_code = pop_account_matcher.group(3)

        pop_account_type = ACCOUNT_ABBREVIATION_TO_FULL_TYPE.get(pop_abbreviated_type)
        if not pop_account_type:
            raise ValueError(
                    'Invalid account type abbreviation <{}> for <{}>'.format(
                        pop_abbreviated_type,
                        name
                    )
                )

        pop_primary_region = AIRPORT_TO_REGION_CODES.get(pop_airport_code)
        if not pop_primary_region:
            raise ValueError(
                    'Invalid airport code <{}> for <{}>'.format(
                        pop_airport_code,
                        name
                    )
                )

        first_index_char =  account_index[0]

        deployment_environment = DEPLOYMENT_ENVIRONMENT_PROD

        if first_index_char == '0':
            second_index_char = account_index[1]

            deployment_environment = PREPROD_DEPLOYMENT_ENVIRONMENTS_INDEX.get(second_index_char)
            if not deployment_environment:
                raise ValueError(
                        'Invalid account index <{}> for <{}>'.format(
                            account_index,
                            name
                        )
                    )

        return PopAccountData(
                name,
                account_id,
                deployment_environment,
                pop_account_type,
                pop_primary_region
            )

SUPPORTED_ENVIRONMENT = SupportedEnvironment(
    AWS_CONNECTORS,
    AWS_REGIONS,
    REGION_CODES,
    REGION_TO_AIRPORT_CODES,
    LEGACY_ACCOUNTS,
    POP_ACCOUNTS
)
