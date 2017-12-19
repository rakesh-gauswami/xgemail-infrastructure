# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Syntax and standards checking code for use with CI.

Copyright 2016-2017, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""


import sys


# There is an AWS CLI function that validates CloudFormation templates, but
# we aim to go beyond that and check parameter files and their relationship
# with the corresponding template.
#
# This is a start, but we'd like to make it even more comprehensive.
# Someday, we'd like to:
#
# * Handle YAML.  Hint: the python yaml module won't parse CloudFormation
#   templates without registering constructors for intrinsic functions
#   like !Ref.  See the "Constructors, representers, resolvers" section
#   in https://pyyaml.org/wiki/PyYAMLDocumentation.
#
# * Check arguments to Ref and Fn:GetAtt functions for validity
#   Be sure to account for pre-defined values.
#
# * Recommend use of built-in types for referenced parameters
#   used in well-defined contexts.
#
# * If a template parameter entry specifies allowed values, check that
#   the value in the corresponding parameter files is one of those values.
#
# * Identify unreferenced parameters.
#
# * Check JSON using a forgiving parser that identifies multiple errors,
#   e.g. missing or extra commas, use of single quotes instead of double quotes,
#   presence of javascript /**/ or // comments, missing or mismatched braces,
#   curly braces, and parentheses, etc.
#
# * Detect circular dependencies in security group ingress/egress rules,
#   or at least warn that dependencies between security groups should be
#   in explicit ingress and egress resources and not embedded in security
#   group resource definitions.
#
# We can dream, can't we?
#
class CloudFormationChecker(object):
    """
    Check CloudFormation template and parameter files for various errors.
    """

    TOP_LABEL = "root"

    MAX_PARAMETER_COUNT = 60

    TEMPLATE_KEYS = set([
        "AWSTemplateFormatVersion",
        "Description",
        "Metadata",
        "Parameters",
        "Mappings",
        "Conditions",
        "Resources",
        "Outputs",
    ])

    TEMPLATE_PARAMETER_KEYS = set([
        "Type",
        "Default",
        "NoEcho",
        "AllowedValues",
        "AllowedPattern",
        "MaxLength",
        "MinLength",
        "MaxValue",
        "MinValue",
        "Description",
        "ConstraintDescription",
    ])

    TEMPLATE_PARAMETER_TYPES = set([
        "String",
        "List<String>",
        "Number",
        "List<Number>",
        "CommaDelimitedList",
        "AWS::EC2::AvailabilityZone::Name",
        "List<AWS::EC2::AvailabilityZone::Name>",
        "AWS::EC2::Instance::Id",
        "List<AWS::EC2::Instance::Id>",
        "AWS::EC2::Image::Id",
        "List<AWS::EC2::Image::Id>",
        "AWS::EC2::KeyPair::KeyName",
        "AWS::EC2::SecurityGroup::GroupName",
        "List<AWS::EC2::SecurityGroup::GroupName>",
        "AWS::EC2::SecurityGroup::Id",
        "List<AWS::EC2::SecurityGroup::Id>",
        "AWS::EC2::Subnet::Id",
        "List<AWS::EC2::Subnet::Id>",
        "AWS::EC2::Volume::Id",
        "List<AWS::EC2::Volume::Id>",
        "AWS::EC2::VPC::Id",
        "List<AWS::EC2::VPC::Id>",
        "AWS::Route53::HostedZone::Id",
        "List<AWS::Route53::HostedZone::Id>",
    ])

    TEMPLATE_RESOURCE_TYPES = set([
        "AWS::ApiGateway::Account",
        "AWS::ApiGateway::Deployment",
        "AWS::ApiGateway::RestApi",
        "AWS::ApiGateway::Stage",

        "AWS::AutoScaling::AutoScalingGroup",
        "AWS::AutoScaling::LaunchConfiguration",
        "AWS::AutoScaling::LifecycleHook",
        "AWS::AutoScaling::ScalingPolicy",
        "AWS::AutoScaling::ScheduledAction",

        "AWS::CertificateManager::Certificate",

        "AWS::CloudFront::Distribution",

        "AWS::CloudWatch::Alarm",

        "AWS::EC2::DHCPOptions",
        "AWS::EC2::EIP",
        "AWS::EC2::Instance",
        "AWS::EC2::InternetGateway",
        "AWS::EC2::NatGateway",
        "AWS::EC2::NetworkInterface",
        "AWS::EC2::Route",
        "AWS::EC2::RouteTable",
        "AWS::EC2::SecurityGroup",
        "AWS::EC2::SecurityGroupEgress",
        "AWS::EC2::SecurityGroupIngress",
        "AWS::EC2::Subnet",
        "AWS::EC2::SubnetRouteTableAssociation",
        "AWS::EC2::VPC",
        "AWS::EC2::VPCDHCPOptionsAssociation",
        "AWS::EC2::VPCEndpoint",
        "AWS::EC2::VPCGatewayAttachment",

        "AWS::EMR::Cluster",

        "AWS::ElastiCache::CacheCluster",
        "AWS::ElastiCache::ParameterGroup",
        "AWS::ElastiCache::ReplicationGroup",
        "AWS::ElastiCache::SubnetGroup",

        "AWS::ElasticLoadBalancing::LoadBalancer",
        "AWS::ElasticLoadBalancingV2::LoadBalancer",
        "AWS::ElasticLoadBalancingV2::TargetGroup",
        "AWS::ElasticLoadBalancingV2::Listener",
        "AWS::ElasticLoadBalancingV2::ListenerRule",

        "AWS::Events::Rule",

        "AWS::IAM::InstanceProfile",
        "AWS::IAM::ManagedPolicy",
        "AWS::IAM::Policy",
        "AWS::IAM::Role",
        "AWS::IAM::User",

        "AWS::Kinesis::Stream",

        "AWS::KinesisFirehose::DeliveryStream",

        "AWS::Lambda::EventSourceMapping",
        "AWS::Lambda::Function",
        "AWS::Lambda::Permission",
        "AWS::Lambda::Version",

        "AWS::Logs::LogGroup",
        "AWS::Logs::MetricFilter",

        "AWS::RDS::DBInstance",
        "AWS::RDS::DBParameterGroup",
        "AWS::RDS::DBSubnetGroup",

        "AWS::Route53::HostedZone",
        "AWS::Route53::RecordSet",

        "AWS::S3::Bucket",
        "AWS::S3::BucketPolicy",

        "AWS::SDB::Domain",

        "AWS::SNS::Subscription",
        "AWS::SNS::Topic",
        "AWS::SNS::TopicPolicy",

        "AWS::SQS::Queue",
        "AWS::SQS::QueuePolicy",

        "Custom::AcmCertificateRequest",
        "Custom::CloudFrontAcmAssociation",
        "Custom::ImageSearch",
        "Custom::LightningTest",
        "Custom::SesConfigurationSet",
        "Custom::SesDomain",
        "Custom::DomainIdentity",
        "Custom::SesFilter",
        "Custom::SesRule",
    ])

    TEMPLATE_RESOURCE_TYPES_WITHOUT_PROPERTIES = set([
        "AWS::SDB::Domain",
        "AWS::SNS::Topic"
    ])

    TEMPLATE_OUTPUTS_KEYS = set([
        "Description",
        "Value",
        "Condition",
    ])

    PARAMETER_KEYS = set([
        "ParameterKey",
        "ParameterValue",
    ])

    PSEUDO_PARAMETERS = set([
        # Reference: http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html
        "AWS::AccountId",
        "AWS::NotificationARNs",
        "AWS::NoValue",
        "AWS::Partition",
        "AWS::Region",
        "AWS::StackId",
        "AWS::StackName",
        "AWS::URLSuffix",
    ])

    def __init__(self):
        """
        Construct a default CloudFormationChecker object that checks nothing.
        """

        self.error_stream = sys.stderr

        self.template_path = None
        self.template_data = None

        self.parameter_path = None
        self.parameter_data = None

        self.weather_wizard = False

        self._passed = True

    def set_error_stream(self, error_stream):
        """
        Set the stream to send error messages to.
        """

        self.error_stream = error_stream

    def set_template_data(self, data, path):
        """
        Set the template data to check and specify the path it was read from.
        """

        self.template_data = data
        self.template_path = path

    def set_parameter_data(self, data, path):
        """
        Set the parameter data to check and specify the path it was read from.
        """

        self.parameter_data = data
        self.parameter_path = path

    def set_weather_wizard(self, weather_wizard):
        """
        Set the weather wizard flag to indicate that parameters might be specified as dictionary objects.
        """

        self.weather_wizard = weather_wizard

    def _error(self, message):
        """
        Record an error by setting the passed flag to False and sending the message to the error stream.
        """

        self._passed = False
        if self.error_stream is not None:
            print >> self.error_stream, message

    def _check_data_type(self, path, label, data, expected_types):
        """
        Check that the given data is one of the expected types.
        """

        if not isinstance(expected_types, list):
            if not isinstance(expected_types, set):
                if not isinstance(expected_types, dict):
                    expected_types = [expected_types]

        for expected_type in expected_types:
            if isinstance(data, expected_type):
                return True

        expected_type_names = [t.__name__ for t in expected_types]
        self._error("%s: %s has type %s, expected one of %s" % (
            path, label, data.__class__.__name__, expected_type_names))

        return False

    def _check_only_allowed_keys(self, path, label, data, allowed_keys):
        """
        Check that the given data (a dictionary) has only the given keys.
        """

        only_allowed_keys = True

        for key in sorted(data.keys()):
            if key not in allowed_keys:
                self._error("%s: %s contains an entry with invalid key %s" % (path, label, key))
                only_allowed_keys = False

        return only_allowed_keys

    def _check_references(self, path, data):
        """
        Check that each instance of the Ref function refers to either a pseudo-parameter, a parameter, or a resource.
        """

        def check_references_helper(path, data, parameters, mappings, conditions, resources):
            # Check various built-in functions.
            if isinstance(data, dict) and len(data) == 1:
                func, arg = data.items()[0]

                if func == "Ref":
                    if arg not in parameters and arg not in resources:
                        self._error("%s: contains Ref referencing non-existent parameter or resource %s" % (path, arg))

                elif func == "Fn::GetAtt":
                    resource = arg[0]
                    if resource not in resources:
                        self._error("%s: contains Fn::GetAtt referencing non-existent resource %s" % (path, resource))

                elif func == "Fn::FindInMap":
                    mapping = arg[0]
                    if mapping not in mappings:
                        self._error("%s: contains Fn::FindInMap referencing non-existent mapping %s" % (path, mapping))

                elif func == "Fn::If":
                    condition = arg[0]
                    if condition not in conditions:
                        self._error("%s: contains Fn::If referencing non-existent condition %s" % (path, condition))

                elif func == "Condition":
                    condition = arg
                    if condition not in conditions:
                        self._error("%s: contains Condition referencing non-existent condition %s" % (path, condition))

            # Recurse.
            items = []
            if isinstance(data, dict):
                items.extend(data.values())
            elif isinstance(data, list):
                items.extend(data)
            for item in items:
                check_references_helper(path, item, parameters, mappings, conditions, resources)

        parameters = set(data["Parameters"].keys() if isinstance(data.get("Parameters"), dict) else [])
        parameters.update(self.PSEUDO_PARAMETERS)

        mappings = set(data["Mappings"].keys() if isinstance(data.get("Mappings"), dict) else [])

        conditions = set(data["Conditions"].keys() if isinstance(data.get("Conditions"), dict) else [])

        resources = set(data["Resources"].keys() if isinstance(data.get("Resources"), dict) else [])

        # Check everything except the top-level Metadata.
        # This reduces the scope of this change by not complaining about all the
        # damned {"Ref":"Description"} hacks, which we should really get rid of.
        for k, v in data.items():
            if k != "Metadata":
                check_references_helper(path, v, parameters, mappings, conditions, resources)

    def _check_key_value(self, path, data_label, data, key, expected_types=None, expected_values=None):
        """
        Check that data[key] has one of the expected types and values.
        """

        if key not in data:
            self._error("%s: %s is missing required key %s" % (path, data_label, key))
            return False

        data_key_label = "%s['%s']" % (data_label, key)

        if expected_types is not None:
            if not self._check_data_type(path, data_key_label, data[key], expected_types):
                return False

        if expected_values is not None:
            if not isinstance(expected_values, list):
                if not isinstance(expected_values, set):
                    if not isinstance(expected_values, dict):
                        expected_values = [expected_values]
            if data[key] not in expected_values:
                self._error("%s: %s['%s'] has invalid value %s" % (path, data_label, key, repr(data[key])))
                return False

        return True

    def check_template_data(self):
        """
        Check the CloudFormation data specified to the set_template_data method.
        """

        path = self.template_path
        data = self.template_data

        if not self._check_data_type(path, self.TOP_LABEL, data, dict):
            return self._passed

        self._check_only_allowed_keys(path, self.TOP_LABEL, data, self.TEMPLATE_KEYS)

        self._check_references(path, data)

        # The required tags, to look like this (sans the line breaks, indentation and contents shown below):

        # "AWSTemplateFormatVersion": "2010-09-09",
        # "Description": "MongoDB auto-scaling group for a single replica set member.",
        # "Metadata": {
        #     "Copyright": [ "Copyright 2016 ...", "respective owners." ],
        #     "Comments": [ { "Ref": "Description" }, " ", "The template follows ...", "number of instances.", "" ]
        # }

        self._check_key_value(path, self.TOP_LABEL, data, "AWSTemplateFormatVersion", unicode, "2010-09-09")
        self._check_key_value(path, self.TOP_LABEL, data, "Description", unicode)
        self._check_key_value(path, self.TOP_LABEL, data, "Metadata", dict)

        # Parameters are optional.
        if "Parameters" in data:
            if self._check_key_value(path, self.TOP_LABEL, data, "Parameters", dict):
                if len(data["Parameters"]) > self.MAX_PARAMETER_COUNT:
                    self._error("%s: %s['Parameters'] has more %d entries, limit is %d" % (
                        path, self.TOP_LABEL, len(data["Parameters"]), self.MAX_PARAMETER_COUNT))
                for parameter, entry in sorted(data["Parameters"].items()):
                    label = "%s['Parameters']['%s']" % (self.TOP_LABEL, parameter)
                    self._check_only_allowed_keys(path, label, entry, self.TEMPLATE_PARAMETER_KEYS)
                    self._check_key_value(path, label, entry, "Type", unicode, self.TEMPLATE_PARAMETER_TYPES)

        # Mappings are optional.
        if "Mappings" in data:
            self._check_key_value(path, self.TOP_LABEL, data, "Mappings", dict)

        # Conditions are optional.
        if "Conditions" in data:
            self._check_key_value(path, self.TOP_LABEL, data, "Conditions", dict)

        # Resources is required.
        if self._check_key_value(path, self.TOP_LABEL, data, "Resources", dict):
            for name, resource in sorted(data["Resources"].items()):
                label = "%s['Resources']['%s']" % (self.TOP_LABEL, name)
                self._check_key_value(path, label, resource, "Type", unicode, self.TEMPLATE_RESOURCE_TYPES)
                if not resource["Type"] in self.TEMPLATE_RESOURCE_TYPES_WITHOUT_PROPERTIES:
                    self._check_key_value(path, label, resource, "Properties", dict)

        # Outputs is optional.
        if "Outputs" in data:
            if self._check_key_value(path, self.TOP_LABEL, data, "Outputs", dict):
                for output, entry in sorted(data["Outputs"].items()):
                    label = "output '%s'" % output
                    self._check_only_allowed_keys(path, label, entry, self.TEMPLATE_OUTPUTS_KEYS)

        return self._passed

    def check_parameter_data(self):
        """
        Check the CloudFormation data specified to the set_parameter_data method.
        """

        path = self.parameter_path
        data = self.parameter_data

        if not self._check_data_type(path, self.TOP_LABEL, data, list):
            return self._passed

        parameter_value_types = [unicode]
        if self.weather_wizard:
            parameter_value_types.append(dict)

        # Make sure each parameter entry has a key string and value string.
        for i, entry in enumerate(data):
            label = "entry %s" % str(i+1)

            if self._check_data_type(path, label, entry, dict):
                if "ParameterKey" in entry:
                    label += " (%s)" % entry["ParameterKey"]

                self._check_only_allowed_keys(path, label, entry, self.PARAMETER_KEYS)

                for parameter_key in self.PARAMETER_KEYS:
                    self._check_key_value(path, label, entry, parameter_key, parameter_value_types)

        return self._passed

    def check_parameter_consistency(self):
        """
        Check the consistency between template and parameter data specified to the
        set_template_data and set_parameter_data methods.
        """

        # Every template parameter must have either a default value or a
        # corresponding entry in the parameter file.

        template_parameters = self.template_data.get("Parameters", {})

        parameters = dict()
        for parameter_entry in self.parameter_data:
            key = parameter_entry.get("ParameterKey", "")
            value = parameter_entry.get("ParameterValue", "")
            parameters[key] = value

        for name in sorted(template_parameters.keys()):
            template_entry = template_parameters[name]

            # This template parameter has a default value,
            # so no need to complain if it doesn't exist in the parameter data.
            if "Default" in template_entry:
                continue

            self._check_key_value(self.parameter_path, "parameters list", parameters, name)

        # Every parameter setting must have a corresponding template parameter.

        for key in parameters:
            self._check_key_value(self.template_path, "template parameters", template_parameters, key, dict)

        return self._passed

    def check_all(self):
        """
        Check everything; return True if all checks passed, else False.
        """

        if self.template_data is not None:
            self.check_template_data()

        if self.parameter_data is not None:
            self.check_parameter_data()

        if self.template_data is not None:
            if self.parameter_data is not None:
                if self._passed:
                    self.check_parameter_consistency()

        return self._passed
