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
    def associate_clean_ip ()
      begin
        ec2 = Aws::EC2::Client.new(region: node['sophos_cloud']['region'])
        resp = ec2.describe_addresses({
            filters: [
                {
                    name: 'tag:Name',
                    values: [
                        'xgemail-outbound'
                    ]
                },
                {
                    name: 'tag:blacklist',
                    values: [
                        '0'
                    ]
                }
            ],
        })[:addresses].select{ |addr| !addr.association_id }
        Chef::Log.debug(resp)
        resp.each do |a|
          Chef::Log.debug(a)
            association = ec2.associate_address({
                allocation_id: a.allocation_id,
                instance_id: node['ec2']['instance_id'],
            })
            Chef::Log.info("Associated EIP: #{a.public_ip} Association Id: #{association.association_id}")
            return a.public_ip
        end
      rescue Aws::EC2::Errors::ResourceAlreadyAssociated => e
        Chef::Log.warn("Try again. EIP already in use. #{e.code}: #{e.message}")
          sleep(1)
          retry
      rescue Aws::EC2::Errors::RequestLimitExceeded => e
        Chef::Log.warn("Rate Limited. #{e.code}: #{e.message}")
          sleep(30)
          retry
      rescue Aws::EC2::Errors::ServiceError => e
          Chef::Log.error("Unhandled ServiceError Exception: #{e.code}: #{e.message}")
          raise "ERROR: Unhandled ServiceError Exception: #{e.code}: #{e.message}"
      end
    end

    def get_hostname ( type )
      region = node['sophos_cloud']['region']
      account = node['sophos_cloud']['environment']
      case type
        when 'submit'
          return "mx-01-#{region}.#{account}.hydra.sophos.com"
        when 'customer-submit'
          return "relay-#{region}.#{account}.hydra.sophos.com"
        when 'customer-encryption'
                  return "encryption-#{region}.#{account}.hydra.sophos.com"
        when 'internet-delivery', 'internet-xdelivery'
          # Get a clean EIP from the pool and associate to the instance, errors are handled within the function
          eip = associate_clean_ip()
          begin
            # Lookup the reverse DNS record of the EIP and use it as postfix hostname
            Chef::Log.info("Getting reverse DNS of EIP: #{eip}")
            hostname = Resolv.getname "#{eip}"
            raise "Resolved hostname is empty for EIP <#{eip}>" if hostname.nil?
            Chef::Log.info("Setting postfix hostname: #{hostname}")
            return hostname
          rescue
            Chef::Log.error("ERROR: Cannot resolve hostname from EIP <#{eip}>. Cannot Continue. Exiting")
            raise "ERROR: Cannot resolve hostname from EIP <#{eip}>. Cannot Continue."
          end
        else
          mac = node['macaddress'].downcase
          subnet_id = node['ec2']['network_interfaces_macs'][mac]['subnet_id']
          destination_cidr_block = '0.0.0.0/0'
          begin
            ec2 = Aws::EC2::Client.new(region: region)
            resp = ec2.describe_route_tables({
                filters:[{
                    name:'association.subnet-id',
                    values:[subnet_id]
                }]
            })
            resp.route_tables[0].routes.each do |r|
              if destination_cidr_block == r.destination_cidr_block
                return "outbound-#{ec2.describe_nat_gateways({
                    nat_gateway_ids: [r.nat_gateway_id],
                }).nat_gateways[0].nat_gateway_addresses[0].public_ip.gsub('.','-')}-#{region}.#{account}.hydra.sophos.com"
              end
            end
          rescue Aws::EC2::Errors::ServiceError => e
            Chef::Log.error("ERROR: Unknown error #{e.message}. Cannot Continue. Exiting")
            raise "ERROR: Unknown error #{e.message}. Cannot Continue. Exiting"
          end
      end
    end
  end
end