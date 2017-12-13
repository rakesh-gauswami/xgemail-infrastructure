# (c) 2014, Dean Wilson <dean.wilson(at)gmail.com>
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.
# Refactored for Ansible 2.0 by Josh Quint  josh at turinggroup.com

# Modified for Boto3 by Matt Marchany <matt.marchany(at)sophos.com>
# Implemented exponential throttling delay by John McGourty <john.mcgourty(at)sophos.com>

from ansible import errors
from ansible.plugins.lookup import LookupBase
import sys
import time
from traceback import format_exception

try:
    import boto3
    import botocore
except ImportError:
    raise errors.AnsibleError(
        "Can't LOOKUP(cloudformation): module boto3 is not installed")

_result_cache = {}

def _add_value_to_cache(key, value):
    _result_cache[key] = value

def _get_value_from_cache(key):
    return _result_cache.get(key)

def _get_default_value(terms):
    if len(terms) > 1:
        key, value = terms[1].split('=')

        if key == 'default':
            return value

    return

class Cloudformation(object):

    def __init__(self, region, stack_name, indent="    "):
        self.region = region
        self.stack_name = stack_name
        self._indent = indent

    def _increase_delay(self, rate_limit_delay, attempts):
        if rate_limit_delay == 0:
            rate_limit_delay = 1
            print self._indent + self._indent + \
                  "Request Limit Exceeded. Waiting {0} seconds, before retrying. Attempt {1}".format(
                      rate_limit_delay, attempts)
        elif rate_limit_delay < 16:
            rate_limit_delay *= 2
            print self._indent + self._indent + \
                  "Request Limit Exceeded. Waiting {0} seconds, before retrying. Attempt {1}".format(
                      rate_limit_delay, attempts)
        else:
            print self._indent + self._indent + \
                  "Request Limit Exceeded. Waiting {0} seconds, before retrying. Attempt {1}".format(
                      rate_limit_delay, attempts)
        return rate_limit_delay

    def _construct_response(self, resource_type, key, stack, default=None):
        if resource_type == 'output':
            if default is not None and len(stack['Stacks']) == 0:
                return [default]
            elif default is not None and 'Outputs' not in stack['Stacks'][0]:
                return [default]
            value = [item['OutputValue'] for item in stack['Stacks'][0]['Outputs'] if item['OutputKey'] == key]
            if len(value) != 0:
                return value
            elif default is not None:
                return [default]
            raise errors.AnsibleError("Could not get value for {0} {1} and no default is set.".format(
                resource_type, key))
        else:
            raise errors.AnsibleError("{0} is not a supported resource type.".format(resource_type))

    def get_item(self, resource_type, key, default=None):
        conn = boto3.client('cloudformation', region_name=self.region)
        rate_limit_delay = 0
        attempts = 0
        stack = {
            "Stacks": []
        }
        running = True
        while running:
            if rate_limit_delay > 0:
                time.sleep(rate_limit_delay)
            attempts += 1
            try:
                stack = conn.describe_stacks(StackName=self.stack_name)
                running = False
            except botocore.exceptions.ClientError as e:
                if e.response['Error']['Code'] == 'Throttling':
                    rate_limit_delay = self._increase_delay(rate_limit_delay, attempts)
                elif e.response['Error']['Code'] == 'ValidationError':
                    return [default]
                else:
                    raise errors.AnsibleError(
                        "Client error describing stack {0}. Exception: {1}".format(self.stack_name, e.message))
            except Exception as e:
                raise errors.AnsibleError(
                    "Exception describing stack {0}. Exception: {1}".format(self.stack_name, e.message))
        try:
            return self._construct_response(resource_type, key, stack, default)
        except errors.AnsibleError as e:
            raise e
        except Exception as e:
            raise errors.AnsibleError(
                "Exception parsing {0} {1} for stack {2}. Exception: {3}".format(
                    resource_type, key, self.stack_name, e.message))

class LookupModule(LookupBase):

    def __init__(self, basedir=None, **kwargs):
        self.basedir = basedir

    def run(self, terms, inject=None, **kwargs):
        try:
            _cached_value = _get_value_from_cache(terms[0])

            if _cached_value is None:
                # split the first term that specifies the name of the stack and the object key
                region, stack, value_type, key = terms[0].split('/')
                # retrieve the default value from the second term
                default = _get_default_value(terms)
                # create a cloudformation object...
                self.cfn = Cloudformation(region, stack)
                # used to retrieve the stack output value
                value = self.cfn.get_item(value_type, key, default)
                # add the value to the internal cache
                _add_value_to_cache(terms[0], value)

                return value
            else:
                return _cached_value

        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            raise errors.AnsibleError(
                format_exception(exc_type, exc_value, exc_traceback))
