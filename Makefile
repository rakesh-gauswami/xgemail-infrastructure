# vim: autoindent noexpandtab tabstop=8 softtabstop=8 shiftwidth=8 filetype=make

# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# Perform sanity checking on source files.

# We should add checks for shell scripts, python files, js files,
# and run unit tests too.

.PHONY: top check local clean

# Make the default target on laptops the local one that does not have Bamboo
# dependencies.  Hopefully this won't lead to unpleasant surprises.

TARGET = $(shell test `uname` = Darwin && echo local || echo check)

top: $(TARGET)

# These tests only work when run in Bamboo:

BAMBOO_TARGETS = .check.python \
		.check.pyunit.bamboo \
		.check.ruby \
		$(EOL)

# These tests work when run locally:

LOCAL_TARGETS = .check.ansible \
		.check.bash \
		.check.cloudformation \
		.check.copyright \
		.check.docker \
		.check.erb \
		.check.json \
		.check.pyunit.local \
		.check.unvaulted \
		.check.yaml \
		.check.vaulted \
		$(EOL)

# These directories contains python unit tests that can run locally.
# The python unit tests in other directories might not work locally.

PYUNIT_LOCAL_DIRS := ./ansible/roles/vault/files \
		./bamboo \
		./bamboo/mcs-push \
		./cookbooks/sophos-central-border-patrol/files/borderpatrol/tests \
		./cookbooks/sophos-cloud-build-tools/files/default/test/testinfra \
		./cookbooks/sophos-cloud-mongo/files/default \
		./lambda \
		./tools \
		./ww \
		./ww/ww_lib \
		$(EOL)

# Use this target to run all checks.

check: clean $(LOCAL_TARGETS) $(BAMBOO_TARGETS)
	@echo OK

# Use this target to run checks that don't depend on Bamboo.
# At the moment this takes about 10 minutes on a Mac, half spent
# executing python unit tests in the lambda directory.

local: clean $(LOCAL_TARGETS)
	@echo OK

##############################################################################

# Some convenient aliases for cleaning and testing.

clean.ansible:
	rm -f .check.ansible

clean.bash:
	rm -f .check.bash

clean.cf:
	rm -f .check.cloudformation

clean.chef:
	rm -f .check.chef

clean.copyright:
	rm -f .check.copyright

clean.docker:
	rm -f .check.docker

clean.erb:
	rm -f .check.erb

clean.json:
	rm -f .check.json

clean.python:
	rm -f .check.python

clean.pyunit.bamboo:
	rm -f .check.pyunit.bamboo

clean.pyunit.local:
	rm -f .check.pyunit.local

clean.ruby:
	rm -f .check.ruby

clean.vaulted:
	rm -f .check.vaulted

clean.unvaulted:
	rm -f .check.unvaulted

clean.yaml:
	rm -f .check.yaml

test.ansible: .check.ansible

test.bash: .check.bash

test.cf: .check.cloudformation

test.chef: .check.chef

test.copyright: .check.copyright

test.docker: .check.docker

test.erb: .check.erb

test.packer: .check.packer

test.json: .check.json

test.python: .check.python

test.pyunit.bamboo: .check.pyunit.bamboo

test.pyunit.local: .check.pyunit.local

test.ruby: .check.ruby

test.vaulted: .check.vaulted

test.unvaulted: .check.unvaulted

test.yaml: .check.yaml

retest.ansible: clean.ansible test.ansible

retest.bash: clean.bash test.bash

retest.cf: clean.cf test.cf

retest.chef: clean.chef test.chef

retest.config: clean.config test.config

retest.copyright: clean.copyright test.copyright

retest.docker: clean.docker test.docker

retest.erb: clean.erb test.erb

retest.json: clean.json test.json

retest.python: clean.python test.python

retest.pyunit.bamboo: clean.python test.pyunit.bamboo

retest.pyunit.local: clean.python test.pyunit.local

retest.ruby: clean.ruby test.ruby

retest.vaulted: clean.vaulted test.vaulted

retest.unvaulted: clean.unvaulted test.unvaulted

retest.yaml: clean.yaml test.yaml

##############################################################################

ANSIBLE_FILES := $(shell find ./ansible -name '*.yml' -o -name '*.yaml')

NUM_ANSIBLE_FILES=$(shell echo $(ANSIBLE_FILES) | wc -w)

.check.ansible:
	@echo Checking $(NUM_ANSIBLE_FILES) ansible files ...
	@./tools/check_ansible $(ANSIBLE_FILES)
	@touch $@

BASH_FILES := $(shell find . -type f -and -not \( -name "*.py" -or -name "*.erb" -or -path "./.git/*" \) -print0 | xargs -0 egrep -n -H '\#!/bin/(sh|bash)' | grep ':1:' | cut -d ':' -f 1)

NUM_BASH_FILES=$(shell echo $(BASH_FILES) | wc -w)

.check.bash: $(BASH_FILES) ./tools/check_bash
	@echo Checking $(NUM_BASH_FILES) bash files ...
	@./tools/check_bash $(BASH_FILES)
	@touch $@

DOCKER_FILES := $(shell find ./docker -name 'Dockerfile')

NUM_DOCKER_FILES=$(shell echo $(DOCKER_FILES) | wc -w)

.check.docker: $(DOCKER_FILES) ./tools/check_docker
	@echo Checking $(NUM_DOCKER_FILES) docker files ...
	@./tools/check_docker $(DOCKER_FILES)
	@touch $@

JSON_FILES := $(shell find ./cookbooks -name '*.json')
JSON_FILES += $(shell find ./templates -name '*.json')
JSON_FILES += $(shell find ./parameters -name '*.json')
JSON_FILES += $(shell find ./workers -name '*.json')
JSON_FILES += $(shell find ./ww -name '*.json')

NUM_JSON_FILES=$(shell echo $(JSON_FILES) | wc -w)

.check.packer:
	@echo Checking Packer Files
	cd packer && ./check_packer_files.sh

.check.json: $(JSON_FILES) ./tools/check_json
	@echo Checking $(NUM_JSON_FILES) json files ...
	@./tools/check_json $(JSON_FILES)
	@touch $@

PYTHON_FILES := $(shell find ./cookbooks -name '*.py')
PYTHON_FILES += $(shell find ./hopper -name '*.py')
PYTHON_FILES += $(shell find ./workers -name '*.py')
PYTHON_FILES += $(shell find ./ww -name '*.py')
PYTHON_FILES += ./hopper/create-logicmonitor-config
PYTHON_FILES += ./hopper/create-mongo-config
PYTHON_FILES += ./hopper/upload-mongo-config

NUM_PYTHON_FILES=$(shell echo $(PYTHON_FILES) | wc -w)

.check.python: $(PYTHON_FILES) ./tools/check_python
	@echo Checking $(NUM_PYTHON_FILES) python files ...
	@bamboo/pywrap.py ./tools/check_python $(PYTHON_FILES)
	@touch $@

PYUNIT_DIRS := $(shell find . -name test_\*.py | xargs -n 1 dirname | sort -u)

PYUNIT_BAMBOO_DIRS := $(shell python -c "print ' '.join(sorted(list(set('$(PYUNIT_DIRS)'.split()) - set('$(PYUNIT_LOCAL_DIR)'.split()))))")

NUM_PYUNIT_BAMBOO_DIRS=$(shell echo $(PYUNIT_BAMBOO_DIRS) | wc -w)

.check.pyunit.bamboo: $(PYUNIT_BAMBOO_DIRS) tools/check_python_unit_tests
	@echo Checking $(NUM_PYUNIT_BAMBOO_DIRS) directories containing python unit tests ...
	@bamboo/pywrap.py tools/check_python_unit_tests $(PYUNIT_BAMBOO_DIRS)
	@touch $@

NUM_PYUNIT_LOCAL_DIRS=$(shell echo $(PYUNIT_LOCAL_DIRS) | wc -w)

.check.pyunit.local: $(PYUNIT_LOCAL_DIRS) tools/check_python_unit_tests
	@echo Checking $(NUM_PYUNIT_LOCAL_DIRS) directories containing python unit tests ...
	@bamboo/pywrap.py tools/check_python_unit_tests $(PYUNIT_LOCAL_DIRS)
	@touch $@

RUBY_FILES := $(shell find ./cookbooks -name '*.rb')
RUBY_FILES += $(shell find ./workers -name '*.rb')

NUM_RUBY_FILES=$(shell echo $(RUBY_FILES) | wc -w)

.check.ruby: $(RUBY_FILES) ./tools/check_ruby
	@echo Checking $(NUM_RUBY_FILES) ruby files ...
	@./tools/check_ruby $(RUBY_FILES)
	@touch $@

ERB_FILES := $(shell find ./cookbooks -name '*.erb')

NUM_ERB_FILES=$(shell echo $(ERB_FILES) | wc -w)

.check.erb: $(ERB_FILES) ./tools/check_erb
	@echo Checking $(NUM_ERB_FILES) erb files ...
	@./tools/check_erb $(ERB_FILES)
	@touch $@

YAML_FILES := $(shell find . -name '*.yml')
YAML_FILES += $(shell find . -name '*.yaml' | grep -v -F .check.yaml)

NUM_YAML_FILES=$(shell echo $(YAML_FILES) | wc -w)

.check.yaml: $(YAML_FILES) ./tools/check_yaml
	@echo Checking $(NUM_YAML_FILES) yaml files ...
	@./tools/check_yaml $(YAML_FILES)
	@touch $@

CLOUDFORMATION_TEMPLATE_FILES  := $(shell find templates/vpc -name '*.json')
CLOUDFORMATION_PARAMETER_FILES := $(shell find parameters/vpc -name '*.json')
CLOUDFORMATION_PARAMETER_FILES += $(shell find ww/parameters -name '*.json')

# TODO: See comment in tools/check_cloudformation re scanning to find template and parameter files.
.check.cloudformation: $(CLOUDFORMATION_TEMPLATE_FILES) $(CLOUDFORMATION_PARAMETER_FILES)
	@echo Checking CloudFormation template and parameter files ...
	@./tools/check_cloudformation -b ami_builder_roles_template.json ami_builder_roles_parameters.json
	@./tools/check_cloudformation -b ami_builder_security_template.json ami_builder_security_parameters.json
	@./tools/check_cloudformation -b ami_builder_vpc_template.json ami_builder_vpc_parameters.json
	@./tools/check_cloudformation -b as_bastion_template.json as_bastion_parameters.json
	@./tools/check_cloudformation -b as_elasticsearch_instance_template.json as_elasticsearch_instance_parameters.json
	@./tools/check_cloudformation -b as_elasticsearch_server_template.json as_logging_elasticsearch_parameters.json
	@./tools/check_cloudformation -b as_kibana_server_template.json as_logging_kibana_parameters.json
	@./tools/check_cloudformation -b as_lnp_template.json as_lnp_parameters.json
	@./tools/check_cloudformation -b as_proxy_template.json as_proxy_api_parameters.json
	@./tools/check_cloudformation -b as_proxy_template.json as_proxy_core_parameters.json
	@./tools/check_cloudformation -b as_proxy_template.json as_proxy_mcs_parameters.json
	@./tools/check_cloudformation -b as_proxy_template.json as_proxy_mob_parameters.json
	@./tools/check_cloudformation -b as_proxy_template.json as_proxy_utm_parameters.json
	@./tools/check_cloudformation -b as_proxy_template.json as_proxy_wifi_parameters.json
	@./tools/check_cloudformation -b as_vpn_template.json as_vpn_parameters.json
	@./tools/check_cloudformation -b cw_log_group_with_filter_and_alarm_template.json cw_log_group_logstash_parameters.json
	@./tools/check_cloudformation -b ec_memcached_template.json ec_memcached_parameters.json
	@./tools/check_cloudformation -b ec_redis_template.json ec_redis_parameters.json
	@./tools/check_cloudformation -b elb_advanced_template.json elb_advanced_akm_parameters.json
	@./tools/check_cloudformation -b elb_advanced_template.json elb_advanced_elasticsearch_client_parameters.json
	@./tools/check_cloudformation -b elb_advanced_template.json elb_advanced_elasticsearch_parameters.json
	@./tools/check_cloudformation -b elb_advanced_template.json elb_advanced_elasticsearch_public_parameters.json
	@./tools/check_cloudformation -b elb_advanced_template.json elb_advanced_kibana_parameters.json
	@./tools/check_cloudformation -b elb_advanced_multi_listener_template.json elb_advanced_logstash_shipper_parameters.json
	@./tools/check_cloudformation -b elb_integration_template.json elb_integration_dep_parameters.json
	@./tools/check_cloudformation -b elb_public_template.json elb_public_api_parameters.json
	@./tools/check_cloudformation -b elb_public_template.json elb_public_core_parameters.json
	@./tools/check_cloudformation -b elb_public_template.json elb_public_csg_parameters.json
	@./tools/check_cloudformation -b elb_public_template.json elb_public_hub_parameters.json
	@./tools/check_cloudformation -b elb_public_template.json elb_public_mail_parameters.json
	@./tools/check_cloudformation -b elb_public_template.json elb_public_mcs_parameters.json
	@./tools/check_cloudformation -b elb_public_template.json elb_public_mob_parameters.json
	@./tools/check_cloudformation -b elb_public_template.json elb_public_smc_parameters.json
	@./tools/check_cloudformation -b elb_public_template.json elb_public_utm_parameters.json
	@./tools/check_cloudformation -b elb_public_template.json elb_public_wifi_parameters.json
	@./tools/check_cloudformation -b image_elasticsearch_instance.json image_elasticsearch_parameters.json
	@./tools/check_cloudformation -b image_logstash_server_template.json image_logstash_server_parameters.json
	@./tools/check_cloudformation -b image_mongodb_template.json image_mongodb_parameters.json
	@./tools/check_cloudformation -b image_push_server_template.json image_push_server_parameters.json
	@./tools/check_cloudformation -b image_xgemail_instance.json image_xgemail_parameters.json
	@./tools/check_cloudformation -b instance_bigdata_pipeline_launcher_template.json instance_bigdata_pipeline_launcher_parameters.json
	@./tools/check_cloudformation -b kinesis_template.json kinesis_customer_change_parameters.json
	@./tools/check_cloudformation -b kinesis_template.json kinesis_endpoint_change_parameters.json
	@./tools/check_cloudformation -b kinesis_template.json kinesis_network_event_parameters.json
	@./tools/check_cloudformation -b kinesis_template.json kinesis_policy_render_parameters.json
	@./tools/check_cloudformation -b kinesis_template.json kinesis_user_change_parameters.json
	@./tools/check_cloudformation -b rds_template.json rds_parameters.json
	@./tools/check_cloudformation -b res_ep_sld_sanitized_template.json res_ep_sld_sanitized_parameters.json
	@./tools/check_cloudformation -b roles_global_template.json roles_global_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_akm_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_api_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_bastion_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_core_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_csg_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_dep_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_elk_elasticsearch_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_elk_elasticsearch_public_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_elk_kibana_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_hub_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_logstash_shipper_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_mail_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_mcs_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_memcached_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_mob_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_redis_logging_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_redis_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_smc_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_utm_parameters.json
	@./tools/check_cloudformation -b route53_record_template.json route53_record_wifi_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_3rdparty_bucket_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_configs_bucket_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_connections_bucket_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_datahub_bucket_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_logging_backup_bucket_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_logging_bucket_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_logic_monitor_bucket_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_stac_private_bucket_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_stac_public_bucket_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_wifi_coredumps_bucket_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_wifi_floorplans_bucket_parameters.json
	@./tools/check_cloudformation -b s3_bucket_template.json s3_xgemail_private_bucket_parameters.json
	@./tools/check_cloudformation -b sdb_domain_template.json -
	@./tools/check_cloudformation -b sg_template.json sg_parameters.json
	@./tools/check_cloudformation -b sg_ops_manager_template.json sg_ops_manager_parameters.json
	@./tools/check_cloudformation -b sns_template.json sns_parameters.json
	@./tools/check_cloudformation -b sqs_sns_subscription_template.json sqs_reader_parameters.json
	@./tools/check_cloudformation -b sqs_sns_subscription_template.json sqs_sns_subscription_parameters.json
	@./tools/check_cloudformation -b vpc_template.json vpc_parameters.json
	@./tools/check_cloudformation -b worker_template.json worker_create_base_ami_parameters.json
	@./tools/check_cloudformation -b worker_template.json worker_create_updated_amazon_linux_ami_parameters.json
	@./tools/check_cloudformation -b worker_template.json worker_create_updated_amazon_nat_ami_parameters.json
	@echo Checking weather-wizard parameter files ...
	@./tools/check_cloudformation -w alb_push_server_template.json alb/public/push_parameters.json
	@./tools/check_cloudformation -w as_ansible_instance_template.json as_ansible_instance_parameters.json
	@./tools/check_cloudformation -w as_bastion_template.json as/bastion_parameters.json
	@./tools/check_cloudformation -w as_cloudera_core_template.json as_cloudera_core_hbase_rs_parameters.json
	@./tools/check_cloudformation -w as_cloudera_data_template.json as_cloudera_data_hbase_rs_parameters.json
	@./tools/check_cloudformation -w as_cloudera_master_template.json as_cloudera_master_hbase_master1_parameters.json
	@./tools/check_cloudformation -w as_cloudera_master_template.json as_cloudera_master_hbase_master2_parameters.json
	@./tools/check_cloudformation -w as_cloudera_master_template.json as_cloudera_master_journalnode_parameters.json
	@./tools/check_cloudformation -w as_cloudera_master_template.json as_cloudera_master_zookeeper1_parameters.json
	@./tools/check_cloudformation -w as_cloudera_master_template.json as_cloudera_master_zookeeper2_parameters.json
	@./tools/check_cloudformation -w as_cloudera_master_template.json as_cloudera_master_zookeeper3_parameters.json
	@./tools/check_cloudformation -w as_cloudera_mgr_instance_template.json as_cloudera_mgr_instance_parameters.json
	@./tools/check_cloudformation -w as_elasticsearch_instance_template.json elasticsearch/client/xgemail_1a_parameters.json
	@./tools/check_cloudformation -w as_elasticsearch_instance_template.json elasticsearch/client/xgemail_1b_parameters.json
	@./tools/check_cloudformation -w as_elasticsearch_instance_template.json elasticsearch/client/xgemail_1c_parameters.json
	@./tools/check_cloudformation -w as_elasticsearch_instance_template.json elasticsearch/data/xgemail_1a_parameters.json
	@./tools/check_cloudformation -w as_elasticsearch_instance_template.json elasticsearch/data/xgemail_1b_parameters.json
	@./tools/check_cloudformation -w as_elasticsearch_instance_template.json elasticsearch/data/xgemail_1c_parameters.json
	@./tools/check_cloudformation -w as_elasticsearch_instance_template.json elasticsearch/master/xgemail_1a_parameters.json
	@./tools/check_cloudformation -w as_elasticsearch_instance_template.json elasticsearch/master/xgemail_1b_parameters.json
	@./tools/check_cloudformation -w as_elasticsearch_instance_template.json elasticsearch/master/xgemail_1c_parameters.json
	@./tools/check_cloudformation -w as_elasticsearch_server_template.json as_logging_elasticsearch_parameters.json
	@./tools/check_cloudformation -w as_internal_web_proxy_template.json as_internal_web_proxy_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_api_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_archivinglifecycle_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_biexport_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_core_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_csg_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_dep_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_dp_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_hub_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_mail_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_mailinbound_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_mailoutbound_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_mcs_default_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_mcs_registration_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_mcs_status_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_mob_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_smc_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_utm_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_slec_parameters.json
	@./tools/check_cloudformation -w as_java_instance_template.json as_java_wifi_parameters.json
	@./tools/check_cloudformation -w as_kibana_server_template.json as_logging_kibana_parameters.json
	@./tools/check_cloudformation -w kinesis_template.json kinesis_auditing_events_parameters.json
	@./tools/check_cloudformation -w kinesis_template.json kinesis/push_parameters.json
	@./tools/check_cloudformation -w as_lnp_template.json as/lnp_parameters.json
	@./tools/check_cloudformation -w as_logicmonitor_collector_template.json as_logicmonitor_collector_parameters.json
	@./tools/check_cloudformation -w as_logstash_server_template.json as_logging_logstash_shipper_parameters.json
	@./tools/check_cloudformation -w as_mongodb_client_instance_template.json as_mongodb_client_instance_parameters.json
	@./tools/check_cloudformation -w as_mongodb_instance_template.json as_mongodb_configsvr_a_parameters.json
	@./tools/check_cloudformation -w as_mongodb_instance_template.json as_mongodb_configsvr_b_parameters.json
	@./tools/check_cloudformation -w as_mongodb_instance_template.json as_mongodb_configsvr_c_parameters.json
	@./tools/check_cloudformation -w as_mongodb_instance_template.json as_mongodb_instance_a_parameters.json
	@./tools/check_cloudformation -w as_mongodb_instance_template.json as_mongodb_instance_b_parameters.json
	@./tools/check_cloudformation -w as_mongodb_instance_template.json as_mongodb_instance_c_parameters.json
	@./tools/check_cloudformation -w as_push_load_generator_template.json as_push_load_generator_parameters.json
	@./tools/check_cloudformation -w as_push_server_template.json as_push_parameters.json
	@./tools/check_cloudformation -w as_smc_wildfly_instance_template.json as/smc_wildfly_cloudif_parameters.json
	@./tools/check_cloudformation -w as_smc_wildfly_instance_template.json as/smc_wildfly_deviceif_parameters.json
	@./tools/check_cloudformation -w as_smc_wildfly_instance_template.json as/smc_wildfly_userif_parameters.json
	@./tools/check_cloudformation -w as_smc_wildfly_instance_template.json as/smc_wildfly_worker_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_1a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_1b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_1c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_2a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_2b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_2c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_3a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_3b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_3c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_4a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_4b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/delivery/xgemail_4c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_1a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_1b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_1c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_2a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_2b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_2c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_3a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_3b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_3c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_4a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_4b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/internet-delivery/xgemail_4c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/submit/xgemail_1a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/submit/xgemail_1b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/submit/xgemail_1c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/submit/xgemail_2a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/submit/xgemail_2b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/submit/xgemail_2c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/customer-submit/xgemail_1a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/customer-submit/xgemail_1b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/customer-submit/xgemail_1c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/customer-submit/xgemail_2a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/customer-submit/xgemail_2b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_instance_template.json email/customer-submit/xgemail_2c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_xdelivery_template.json email/xdelivery/xgemail_1a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_xdelivery_template.json email/xdelivery/xgemail_1b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_xdelivery_template.json email/xdelivery/xgemail_1c_parameters.json
	@./tools/check_cloudformation -w as_xgemail_xdelivery_template.json email/internet-xdelivery/xgemail_1a_parameters.json
	@./tools/check_cloudformation -w as_xgemail_xdelivery_template.json email/internet-xdelivery/xgemail_1b_parameters.json
	@./tools/check_cloudformation -w as_xgemail_xdelivery_template.json email/internet-xdelivery/xgemail_1c_parameters.json
	@./tools/check_cloudformation -w bakery_asg_template.json bakery_asg_parameters.json
	@./tools/check_cloudformation -w bakery_vpc_template.json bakery_vpc_parameters.json
	@./tools/check_cloudformation -w cloudfront_template.json cloudfront_stac_public_parameters.json
	@./tools/check_cloudformation -w cw_log_group_with_filter_and_alarm_template.json cw/log_group_logstash_parameters.json
	@./tools/check_cloudformation -w ec_memcached_template.json ec/memcached_parameters.json
	@./tools/check_cloudformation -w ec_redis_template.json ec/redis_logging_parameters.json
	@./tools/check_cloudformation -w ec_redis_template.json ec/redis_parameters.json
	@./tools/check_cloudformation -w ec_redis_template.json ec/smc_redis_parameters.json
	@./tools/check_cloudformation -w elb_advanced_template.json elb/advanced/elasticsearch_client_parameters.json
	@./tools/check_cloudformation -w elb_advanced_template.json elb/advanced/elasticsearch_parameters.json
	@./tools/check_cloudformation -w elb_advanced_template.json elb/advanced/elasticsearch_public_parameters.json
	@./tools/check_cloudformation -w elb_advanced_template.json elb/advanced/email_xdelivery_parameters.json
	@./tools/check_cloudformation -w elb_advanced_template.json elb/advanced/email_internet_xdelivery_parameters.json
	@./tools/check_cloudformation -w elb_advanced_template.json elb/advanced/kibana_parameters.json
	@./tools/check_cloudformation -w elb_advanced_multi_listener_template.json elb/advanced/logstash_shipper_parameters.json
	@./tools/check_cloudformation -w elb_advanced_template.json elb/advanced/smc_worker_parameters.json
	@./tools/check_cloudformation -w elb_advanced_template.json elb_advanced_cloudera_mgr_hb_parameters.json
	@./tools/check_cloudformation -w elb_advanced_template.json elb_advanced_cloudera_mgr_parameters.json
	@./tools/check_cloudformation -w elb_advanced_template.json elb_advanced_internal_web_proxy_parameters.json
	@./tools/check_cloudformation -w elb_integration_template.json elb/integration/dep_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/api_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/archivinglifecycle_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/core_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/csg_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/dp_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/hub_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/mail_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/mailinbound_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/mailoutbound_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/mob_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/smc_cloudif_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/smc_deviceif_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/smc_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/smc_userif_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/utm_parameters.json
	@./tools/check_cloudformation -w elb_public_template.json elb/public/wifi_parameters.json
	@./tools/check_cloudformation -w elb_public_xgemail_template.json elb/public/email_delivery_parameters.json
	@./tools/check_cloudformation -w elb_public_xgemail_template.json elb/public/email_internet_delivery_parameters.json
	@./tools/check_cloudformation -w elb_public_xgemail_template.json elb/public/email_submit_parameters.json
	@./tools/check_cloudformation -w elb_public_xgemail_template.json elb/public/email_customer_submit_parameters.json
	@./tools/check_cloudformation -w elbv2_http_listener_template.json elbv2/mcs/mcs_elbv2_jmx_listener_parameters.json
	@./tools/check_cloudformation -w elbv2_https_listener_template.json elbv2/mcs/mcs_elbv2_application_listener_parameters.json
	@./tools/check_cloudformation -w elbv2_listener_rule_template.json elbv2/mcs/mcs_elbv2_registration_listener_rule_parameters.json
	@./tools/check_cloudformation -w elbv2_simple_template.json elbv2/mcs/mcs_elbv2_parameters.json
	@./tools/check_cloudformation -w emr_private_template.json emr_spark_parameters.json
	@./tools/check_cloudformation -w eni_template.json eni_journalnode_parameters.json
	@./tools/check_cloudformation -w eni_template.json eni_namenode1_parameters.json
	@./tools/check_cloudformation -w eni_template.json eni_namenode2_parameters.json
	@./tools/check_cloudformation -w eni_template.json eni_zookeeper1_parameters.json
	@./tools/check_cloudformation -w eni_template.json eni_zookeeper2_parameters.json
	@./tools/check_cloudformation -w eni_template.json eni_zookeeper3_parameters.json
	@./tools/check_cloudformation -w firehose_log_to_s3_template.json ses-mail-relay/ses-log-delivery-stream-parameters.json
	@./tools/check_cloudformation -w gateway_template.json public_gateway_parameters.json
	@./tools/check_cloudformation -w image_push_load_generator_template.json image/image_push_load_generator_parameters.json
	@./tools/check_cloudformation -w instance_bigdata_pipeline_launcher_template.json instance_bigdata_pipeline_launcher_parameters.json
	@./tools/check_cloudformation -w kinesis_template.json kinesis_network_event_parameters.json
	@./tools/check_cloudformation -w lambda_bi_import_template.json lambda/lambda_bi_import_parameters.json
	@./tools/check_cloudformation -w lambda_push_kinesis_reader_template.json lambda/lambda_push_kinesis_reader_parameters.json
	@./tools/check_cloudformation -w lambda_push_template.json lambda/lambda_push_parameters.json
	@./tools/check_cloudformation -w lambda_ses_cf_handlers_template.json lambda/lambda_ses_cf_handlers_parameters.json
	@./tools/check_cloudformation -w lambda_ses_firehose_instrumenter_template.json lambda/lambda_ses_firehose_instrumenter_parameters.json
	@./tools/check_cloudformation -w lambda_template.json lambda_acm_parameters.json
	@./tools/check_cloudformation -w lambda_template.json lambda_cloudfront_cert_assoc_parameters.json
	@./tools/check_cloudformation -w lambda_template.json lambda_image_search_resource_parameters.json
	@./tools/check_cloudformation -w lambda_template.json lambda/lambda_xgemail_monitor_receive_parameters.json
	@./tools/check_cloudformation -w lambda_template.json lambda/lambda_xgemail_monitor_send_parameters.json
	@./tools/check_cloudformation -w policies_push_template.json policies_push_parameters.json
	@./tools/check_cloudformation -w policies_stac_template.json policies_stac_parameters.json
	@./tools/check_cloudformation -w policy_call_lambda_template.json ses-mail-relay/firehose-call-transform-lambda-policy-parameters.json
	@./tools/check_cloudformation -w policy_firehose_publish_to_s3_template.json ses-mail-relay/firehose-publish-ses-log-to-s3-policy-parameters.json
	@./tools/check_cloudformation -w policy_ses_publish_to_firehose_template.json ses-mail-relay/ses-publish-to-firehose-policy-parameters.json
	@./tools/check_cloudformation -w rds_template.json rds_parameters.json
	@./tools/check_cloudformation -w rds_template.json rds/smc_parameters.json
	@./tools/check_cloudformation -w roles_cloudfront_lambda_template.json -
	@./tools/check_cloudformation -w roles_global_template.json roles/global_parameters.json
	@./tools/check_cloudformation -w roles_image_search_lambda_template.json -
	@./tools/check_cloudformation -w roles_lambda_default_template.json -
	@./tools/check_cloudformation -w roles_lambda_ses_cf_handlers_template.json -
	@./tools/check_cloudformation -w roles_nightly_automation_template.json roles/nightly_automation_parameters.json
	@./tools/check_cloudformation -w roles_region_push_template.json roles/roles_region_push_parameters.json
	@./tools/check_cloudformation -w roles_region_template.json roles/region_parameters.json
	@./tools/check_cloudformation -w roles_simple_template.json ses-mail-relay/firehose-publish-ses-log-to-s3-role-parameters.json
	@./tools/check_cloudformation -w roles_simple_template.json ses-mail-relay/ses-publish-to-firehose-role-parameters.json
	@./tools/check_cloudformation -w roles_xgemail_template.json roles/xgemail_parameters.json
	@./tools/check_cloudformation -w route53_alias_record_template.json route53/record/mcs_elbv2_hmr_alias_parameters.json
	@./tools/check_cloudformation -w route53_cname_record_template.json route53/record/mcs_elbv2_hydra_cname_parameters.json
	@./tools/check_cloudformation -w route53_cname_record_template.json ses-mail-relay/ses-business-mail-domain-dns-dkim-ITER-parameters.json
	@./tools/check_cloudformation -w route53_cname_record_template.json ses-mail-relay/ses-home-mail-domain-dns-dkim-ITER-parameters.json
	@./tools/check_cloudformation -w route53_mx_record_template.json ses-mail-relay/ses-business-mail-domain-mail-from-dns-mx-parameters.json
	@./tools/check_cloudformation -w route53_mx_record_template.json ses-mail-relay/ses-home-mail-domain-mail-from-dns-mx-parameters.json
	@./tools/check_cloudformation -w route53_record_basic_template.json -
	@./tools/check_cloudformation -w route53_record_basic_template.json route53/record/email_delivery_a_record_a_parameters.json
	@./tools/check_cloudformation -w route53_record_basic_template.json route53/record/email_delivery_a_record_b_parameters.json
	@./tools/check_cloudformation -w route53_record_basic_template.json route53/record/email_customer_submit_a_record_parameters.json
	@./tools/check_cloudformation -w route53_record_basic_template.json route53/record/xgemail_mx01_parameters.json
	@./tools/check_cloudformation -w route53_record_basic_template.json route53/record/xgemail_mx02_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53_record_cloudera_mgr_hb_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53_record_cloudera_mgr_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53_record_internal_web_proxy_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53_record_namenode1_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53_record_namenode2_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53_record_zookeeper1_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53_record_zookeeper2_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53_record_zookeeper3_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/api_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/archivinglifecycle_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/core_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/csg_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/dep_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/dp_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/elk_elasticsearch_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/elk_elasticsearch_public_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/elk_kibana_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/email_delivery_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/email_internet_delivery_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/email_xdelivery_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/email_internet_xdelivery_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/hub_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/hydra_hosted_zone_mx_record.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/logstash_shipper_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/mail_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/mailinbound_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/mailoutbound_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/memcached_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/mob_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/push_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/redis_logging_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/redis_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/smc_cloudif_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/smc_deviceif_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/smc_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/smc_rds_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/smc_redis_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/smc_userif_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/stac_cloudfront_public_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/utm_parameters.json
	@./tools/check_cloudformation -w route53_record_template.json route53/record/wifi_parameters.json
	@./tools/check_cloudformation -w route53_subdomain_delegation_template.json ses-mail-relay/dns-business-mail-subdomain-delegation-parameters.json
	@./tools/check_cloudformation -w route53_subdomain_delegation_template.json ses-mail-relay/dns-home-mail-subdomain-delegation-parameters.json
	@./tools/check_cloudformation -w route53_txt_record_template.json ses-mail-relay/ses-business-mail-domain-dns-spf-parameters.json
	@./tools/check_cloudformation -w route53_txt_record_template.json ses-mail-relay/ses-business-mail-domain-dns-verification-parameters.json
	@./tools/check_cloudformation -w route53_txt_record_template.json ses-mail-relay/ses-business-mail-domain-mail-from-dns-spf-parameters.json
	@./tools/check_cloudformation -w route53_txt_record_template.json ses-mail-relay/ses-home-mail-domain-dns-spf-parameters.json
	@./tools/check_cloudformation -w route53_txt_record_template.json ses-mail-relay/ses-home-mail-domain-dns-verification-parameters.json
	@./tools/check_cloudformation -w route53_txt_record_template.json ses-mail-relay/ses-home-mail-domain-mail-from-dns-spf-parameters.json
	@./tools/check_cloudformation -w -t generic s3_bucket_template.json bakery_s3_parameters.json
	@./tools/check_cloudformation -w s3_bucket_sns_notifications_template.json s3/policy_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json archiving/archiving_expiry_bucket.json
	@./tools/check_cloudformation -w s3_bucket_template.json archiving/archiving_message_bucket.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/3rdparty_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/ansible_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/cobranding_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/rolesmanager_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/customer_submit_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/reports_storage_bucket_parameters.json
	@./tools/check_cloudformation -w co_branding_bucket_policy_template.json s3/cobranding_bucket_policy_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/configs_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/connections_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/dp_keyserver_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/emergency_inbox_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/lambda_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/logging_backup_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/logging_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/logs_sophos_central_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/msg_history_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/msg_stats_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/msp_private_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/public_api_documentation_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/quarantine_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/submit_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/smc_mdmfiles_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3_audit_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3_bi_export_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3_bi_export_bucket_replicated_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3_datahub_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3_logicmonitor_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3_stac_private_labs_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3_stac_public_bucket_parameters.json
	@./tools/check_cloudformation -w s3_bucket_template.json s3/hub_account_export_data_bucket_parameters.json
	@./tools/check_cloudformation -w sdb_domain_template.json -
	@./tools/check_cloudformation -w ses_configuration_set_template.json ses-mail-relay/ses_configuration_set_parameters.json
	@./tools/check_cloudformation -w ses_domain_identity_template.json ses-mail-relay/ses-business-mail-domain-identity-parameters.json
	@./tools/check_cloudformation -w ses_domain_identity_template.json ses-mail-relay/ses-home-mail-domain-identity-parameters.json
	@./tools/check_cloudformation -w sg_template.json sg/parameters.json
	@./tools/check_cloudformation -w sg_push_template.json sg/sg_push_parameters.json
	@./tools/check_cloudformation -w sg_push_load_generator_template.json sg/sg_push_load_generator_parameters.json
	@./tools/check_cloudformation -w sg_ops_manager_template.json sg/ops_manager_parameters.json
	@./tools/check_cloudformation -w sg_bi_import_template.json sg/sg_bi_import_parameters.json
	@./tools/check_cloudformation -w sg_xgemail_template.json sg/xgemail_parameters.json
	@./tools/check_cloudformation -w sns_basic_template.json sns/push-ui-parameters.json
	@./tools/check_cloudformation -w sns_lambda_subscribe_template.json sns/push_lifecycle_sns_parameters.json
	@./tools/check_cloudformation -w sns_not_so_simple_template.json sns/xgemail_delay_parameters.json
	@./tools/check_cloudformation -w sns_not_so_simple_template.json sns/xgemail_deleted_events_parameters.json
	@./tools/check_cloudformation -w sns_not_so_simple_template.json sns/xgemail_internet_delivery_parameters.json
	@./tools/check_cloudformation -w sns_not_so_simple_template.json sns/xgemail_policy_parameters.json
	@./tools/check_cloudformation -w sns_not_so_simple_template.json sns/xgemail_quarantined_events_parameters.json
	@./tools/check_cloudformation -w sns_not_so_simple_template.json sns/xgemail_relay_control_parameters.json
	@./tools/check_cloudformation -w sns_not_so_simple_template.json sns/xgemail_success_events_parameters.json
	@./tools/check_cloudformation -w sns_template.json sns/msp_private_bucket_parameters.json
	@./tools/check_cloudformation -w sns_template.json sns/parameters.json
	@./tools/check_cloudformation -w sns_template.json sns/xgemail_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/archiving_lifecycle_sqs_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_customer_delivery_listener_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_customer_delivery_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_customer_submit_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_delay_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_dqs_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_emergency_inbox_listener_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_emergency_inbox_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_msg_history_listener_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_msg_history_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_msg_statistics_listener_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_msg_statistics_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_quarantine_delivery_listener_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_quarantine_delivery_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_internet_delivery_parameters.json
	@./tools/check_cloudformation -w sqs_simple_template.json sqs/xgemail_internet_submit_parameters.json
	@./tools/check_cloudformation -w sqs_template.json sqs/smc_compliance_parameters.json
	@./tools/check_cloudformation -w sqs_template.json sqs/smc_import_data_processor_parameters.json
	@./tools/check_cloudformation -w sqs_template.json sqs/smc_dead_letter_parameters.json
	@./tools/check_cloudformation -w sqs_template.json sqs/smc_transition_parameters.json
	@./tools/check_cloudformation -w sqs_template.json sqs/smc_trigger_parameters.json
	@./tools/check_cloudformation -w sqs_template.json sqs/smc_update_endpoint_parameters.json
	@./tools/check_cloudformation -w sqs_sns_subscription_template.json sqs/reader_parameters.json
	@./tools/check_cloudformation -w sqs_sns_subscription_template.json sqs/sns_subscription_parameters.json
	@./tools/check_cloudformation -w sqs_sns_subscription_template.json sqs_sns_subscription_netcube_pipeline_parameters.json
	@./tools/check_cloudformation -w sqs_sns_subscription_template.json sqs/xgemail_lifecycle_parameters.json
	@./tools/check_cloudformation -w sqs_template.json bakery_sqs_parameters.json
	@./tools/check_cloudformation -w sqs_template.json sqs/ansible_parameters.json
	@./tools/check_cloudformation -w sqs_template.json sqs/nightly_automation_parameters.json
	@./tools/check_cloudformation -w sqs_template.json sqs_stac_private_parameters.json
	@./tools/check_cloudformation -w sqs_template.json sqs_stac_private_labs_parameters.json
	@./tools/check_cloudformation -w sqs_template.json sqs_stac_public_parameters.json
	@./tools/check_cloudformation -w tg_simple_template.json tg/tg-mcs-default-parameters.json
	@./tools/check_cloudformation -w tg_simple_template.json tg/tg-mcs-registration-parameters.json
	@./tools/check_cloudformation -w tg_simple_template.json tg/tg-mcs-status-parameters.json
	@./tools/check_cloudformation -w vpc_template.json -
	@./tools/check_cloudformation -w xgemail_messaging_template.json email/xgemail_messaging_parameters.json
	@touch $@

CHEFSPEC_FILES := $(shell find ./cookbooks -name '*_spec.rb')

NUM_CHEFSPEC_FILES=$(shell echo $(CHEFSPEC_FILES) | wc -w)

.check.chef: $(CHEFSPEC_FILES) ./tools/check_chefspec
	@echo Running $(NUM_CHEFSPEC_FILES) chefspec test files ...
	@./tools/check_chefspec $(CHEFSPEC_FILES)
	@touch $@

COPYRIGHT_FILES := $(shell find ./cookbooks/sophos-cloud* -name '*.rb' \! -name 'metadata.rb')
COPYRIGHT_FILES += $(shell find ./ -name '*.js')
COPYRIGHT_FILES += $(shell find ./templates -name '*.json')
COPYRIGHT_FILES += $(shell find ./ -name '*.sh')
COPYRIGHT_FILES += $(shell find ./ -name '*.py' \! \( -name '__init__.py' \
	-or -name 'ec2.py' \
	-or -name 'acm_handler.py' \
	-or -name 'cfn_resource.py' \
	-or -name 'cloudfront_cert_handler.py' \
	-or -name 'kms_dba_script.py'\
	-or -name 'admin_dba_script.py'\
	-or -name 'aws_regions.py'\
	-or -name 'cloudformation.py'\
	-or -name 'elasticache_replica_group.py'\
	\) )

NUM_COPYRIGHT_FILES=$(shell echo $(COPYRIGHT_FILES) | wc -w)

.check.copyright: $(COPYRIGHT_FILES) ./tools/check_copyright.py
	@echo Checking $(NUM_COPYRIGHT_FILES) files for copyright ...
	@./tools/check_copyright.py $(COPYRIGHT_FILES)
	@touch $@

VAULTED_FILES := $(shell find ./ansible -iname \*_vaulted.yml -or -iname \*_vaulted.yaml)

NUM_VAULTED_FILES=$(shell echo "$(VAULTED_FILES)" | wc -w)

UNVAULTED_FILES := $(shell find ./ansible -iname \*.yml)

NUM_UNVAULTED_FILES=$(shell echo "$(UNVAULTED_FILES)" | wc -w)

.check.vaulted: $(VAULTED_FILES) ./tools/check_vaulted.py
	@echo Checking $(NUM_VAULTED_FILES) vaulted files to make sure they are encrypted ...
	@./tools/check_vaulted.py $(VAULTED_FILES)
	@touch $@

.check.unvaulted: $(UNVAULTED_FILES) ./tools/check_unvaulted.py
	@echo Checking $(NUM_UNVAULTED_FILES) files for leaking secrets or password ...
	@./tools/check_unvaulted.py $(UNVAULTED_FILES)
	@touch $@

clean:
	rm -f .check.*
