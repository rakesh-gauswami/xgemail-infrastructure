# vim: autoindent noexpandtab tabstop=8 softtabstop=8 shiftwidth=8 filetype=make

# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# Perform sanity checking on source files.

# We should add checks for shell scripts, python files, js files,
# and run unit tests too.

.PHONY: top check local clean group1 group2 group3 group4

# Make the default target on laptops the local one that does not have Bamboo
# dependencies.  Hopefully this won't lead to unpleasant surprises.

TARGET = $(shell test `uname` = Darwin && echo local || echo check)

top: $(TARGET)

# These tests only work when run in Bamboo:

BAMBOO_TARGETS = 	.check.python \
		.check.ruby \
		$(EOL)

# These tests work when run locally:

LOCAL_TARGETS = 	.check.ansible \
		.check.bash \
		.check.cloudformation \
		.check.copyright \
		.check.erb \
		.check.yaml \
		$(EOL)

# Build Group 1 - Python Bamboo
GROUP_1 = 	.check.python \
			.check.pyunit.local \
			$(EOL)

# Build Group 2 - CloudFormation Templates
GROUP_2 = 	.check.cloudformation \
			$(EOL)

# Build Group 3 - Everything else
GROUP_3 = 	.check.bash \
			.check.copyright \
			.check.erb \
			.check.ruby \
			.check.yaml \
			$(EOL)

# Build Group 4 - Ansible
GROUP_4 = 	.check.ansible \
			$(EOL)

# These directories contains python unit tests that can run locally.
# The python unit tests in other directories might not work locally.

PYUNIT_LOCAL_DIRS :=  \
		./bamboo \
		./lambda \
		./tools \
		./cookbooks/sophos-cloud-xgemail/files/default \
		./cookbooks/sophos-cloud-xgemail/templates/default \
		$(EOL)

# Use this target to run all checks.

check: clean $(LOCAL_TARGETS) $(BAMBOO_TARGETS)
	@echo OK

# Breakout Bamboo only targets to run in parallel with LOCAL_TARGETS
group1: clean $(GROUP_1)
	@echo OK

group2: clean $(GROUP_2)
	@echo OK

group3: clean $(GROUP_3)
	@echo OK

group4: clean $(GROUP_4)
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

ANSIBLE_FILES := $(shell find ./ansible/playbooks -name '*.yml' -o -name '*.yaml' -maxdepth 1)

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

#DOCKER_FILES := $(shell find ./docker -name 'Dockerfile')
#
#NUM_DOCKER_FILES=$(shell echo $(DOCKER_FILES) | wc -w)
#
#.check.docker: $(DOCKER_FILES) ./tools/check_docker
#	@echo Checking $(NUM_DOCKER_FILES) docker files ...
#	@./tools/check_docker $(DOCKER_FILES)
#	@touch $@

#JSON_FILES := $(shell find ./ansible/roles/ami-xgemail/files/cf_templates -name '*.json')
#JSON_FILES += $(shell find ./ansible/roles/common/files/cf_templates  -name '*.json')

#NUM_JSON_FILES=$(shell echo $(JSON_FILES) | wc -w)

#.check.packer:
#	@echo Checking Packer Files
#	cd packer && ./check_packer_files.sh

#.check.json: $(JSON_FILES) ./tools/check_json
	#@echo Checking $(NUM_JSON_FILES) json files ...
	#@./tools/check_json $(JSON_FILES)
	#@touch $@

PYTHON_FILES := $(shell find ./cookbooks -name '*.py')
PYTHON_FILES += $(shell find ./utils -name '*.py')
#PYTHON_FILES += $(shell find ./bamboo -name '*.py') Need to add a Python3 syntax checker. Files in this directory are all python3 now.
PYTHON_FILES += $(shell find ./bamboo/xgemail -name '*.py')
PYTHON_FILES += ./utils/xgemail_send_eml.py
PYTHON_FILES += ./utils/xgemail_terminate_instance.py
PYTHON_FILES += ./lambda/xgemail_eip_monitor.py
PYTHON_FILES += ./lambda/xgemail_eip_rotation.py
PYTHON_FILES += ./lambda/xgemail_multi_eip_rotation.py
PYTHON_FILES += ./lambda/xgemail_mf_elb_o365_ip_sync.py
PYTHON_FILES += ./lambda/xgemail_instance_terminator.py
PYTHON_FILES += ./lambda/xgemail_firehose_transformation.py

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

# exclude .git folder to avoid problems with branch names containing .yml or .yaml
# see https://stackoverflow.com/a/15736463
YAML_FILES := $(shell find . -path './.git/*' -prune -o -name '*.yml' -print)
YAML_FILES += $(shell find . -path './.git/*' -prune -o -name '*.yaml' -print| grep -v -F .check.yaml)

NUM_YAML_FILES=$(shell echo $(YAML_FILES) | wc -w)

.check.yaml: $(YAML_FILES) ./tools/check_yaml
	@echo Checking $(NUM_YAML_FILES) yaml files ...
	@./tools/check_yaml $(YAML_FILES)
	@touch $@

CLOUDFORMATION_TEMPLATE_FILES  := $(shell find ./ansible/roles/ami-xgemail/files/cf_templates -name '*.json')
CLOUDFORMATION_TEMPLATE_FILES += $(shell find ./ansible/roles/common/files/cf_templates -name '*.json')

.check.cloudformation: $(CLOUDFORMATION_TEMPLATE_FILES)
	@echo Checking CloudFormation template files ...
	@./tools/check_cloudformation $(CLOUDFORMATION_TEMPLATE_FILES)
	@touch $@

CHEFSPEC_FILES := $(shell find ./cookbooks -name '*_spec.rb')

NUM_CHEFSPEC_FILES=$(shell echo $(CHEFSPEC_FILES) | wc -w)

.check.chef: $(CHEFSPEC_FILES) ./tools/check_chefspec
	@echo Running $(NUM_CHEFSPEC_FILES) chefspec test files ...
	@./tools/check_chefspec $(CHEFSPEC_FILES)
	@touch $@

#COPYRIGHT_FILES := $(shell find ./cookbooks/sophos-cloud* -name '*.rb' \! -name 'metadata.rb')
#COPYRIGHT_FILES += $(shell find ./ -name '*.js')
#COPYRIGHT_FILES += $(shell find ./ -name '*_template.json')
#COPYRIGHT_FILES += $(shell find ./ -name '*.sh')
#COPYRIGHT_FILES += $(shell find ./ -name '*.py' \! \( -name '__init__.py' \
#	-or -name 'ec2.py' \
#	-or -name 'cfn_resource.py' \
#	-or -name 'aws_regions.py'\
#	-or -name 'cloudformation.py'\
#	\) )

NUM_COPYRIGHT_FILES=$(shell echo $(COPYRIGHT_FILES) | wc -w)

.check.copyright: $(COPYRIGHT_FILES) ./tools/check_copyright.py
	@echo Checking $(NUM_COPYRIGHT_FILES) files for copyright ...
	@./tools/check_copyright.py $(COPYRIGHT_FILES)
	@touch $@

clean:
	rm -f .check.*
