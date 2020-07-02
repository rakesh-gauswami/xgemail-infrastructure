#
# Cookbook Name:: sophos-cloud-xgemail
# Library:: sophos-cloud-xgemail_helper
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Common code to help with postfix configuration
#

require 'fileutils'
require 'chef/mixin/shell_out'
require 'resolv'

module SophosCloudXgemail
  module Helper

    include Chef::Mixin::ShellOut

    MULTI_GROUP = 'mta'
    POSTFIX_PREFIX = 'postfix'
    POSTMULTI_DEFAULT_INSTANCE = '-'
    QUEUE_BASE_DIRECTORY = '/storage'

    def print_queue_directory ( instance )
      return "#{QUEUE_BASE_DIRECTORY}/#{instance_name(instance)}"
    end

    def instance_name ( name )
      if name == POSTMULTI_DEFAULT_INSTANCE
        return name
      end

      return "#{POSTFIX_PREFIX}-#{name}"
    end

    def print_postmulti_init ( )
      return 'postmulti -e init'
    end

    def print_postconf ( instance, param )
      return "postconf -c /etc/#{instance_name(instance)} -e #{param}"
    end

    def print_postmulti_create ( instance )
      return \
        "postmulti -I '#{instance_name(instance)}'" \
        " -G '#{MULTI_GROUP}'" \
        " -e create" \
        " queue_directory='#{print_queue_directory(instance)}'"
    end

    def print_postmulti_enable ( instance )
      return "#{print_postmulti_prefix(instance)} -e enable"
    end

    def print_postmulti_cmd ( instance, command )
      return "#{print_postmulti_prefix(instance)} -x #{command}"
    end

    def print_postmulti_prefix ( instance )
      return "postmulti -i '#{instance_name(instance)}'"
    end

    def postmulti_config_dir ( instance )
      cmd = shell_out!( "#{print_postmulti_prefix(instance)} -x postconf -h config_directory" )
      retval = cmd.stdout
      retval.chomp!
      return retval
    end

    def cleanup_main_cf ( instance )
      command = 'sed -i ' +
        # Replace line comments with nothing
        '-e \'s/^#.*$//\' ' +
        # Remove lines that are empty or contain white space only
        '-e \'/^\s*$/d\' ' +
        "'#{postmulti_config_dir( instance )}/main.cf'"

      shell_out!( command )
    end

    def cleanup_master_cf ( instance )
      command = 'sed -i ' +
        # Add header to a master service table for easier reference
        '-e \'1i # ==========================================================================\' ' +
        '-e \'1i # service type  private unpriv  chroot  wakeup  maxproc command + args\' ' +
        '-e \'1i #               (yes)   (yes)   (no)    (never) (100)\' ' +
        '-e \'1i # ==========================================================================\' ' +
        # Replace line comments with nothing
        '-e \'s/^#.*$//\' ' +
        # Remove lines that are empty or contain white space only
        '-e \'/^\s*$/d\' ' +
        "'#{postmulti_config_dir( instance )}/master.cf'"

      shell_out!( command )
    end
  end

  module AwsHelper
    def get_hostname ( type )
      region = node['sophos_cloud']['region']
      account = node['sophos_cloud']['environment']
      case type
        when 'customer-submit', 'customer-delivery', 'customer-xdelivery'
          return "relay-#{region}.#{account}.hydra.sophos.com"
        when 'encryption-submit', 'encryption-delivery'
          return "encryption-#{region}.#{account}.hydra.sophos.com"
        when 'internet-submit', 'internet-delivery', 'internet-xdelivery', 'risky-delivery', 'risky-xdelivery', 'warmup-delivery', 'warmup-xdelivery', 'beta-delivery', 'beta-xdelivery', 'delta-delivery', 'delta-xdelivery'
          return "mx-01-#{region}.#{account}.hydra.sophos.com"
      end
    end
  end
end
