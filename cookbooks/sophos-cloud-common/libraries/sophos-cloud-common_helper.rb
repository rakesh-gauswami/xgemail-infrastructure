#
# Cookbook Name:: sophos-cloud-common
# Library:: sophos-cloud-common_helper
#
# Copyright 2017 Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of Sophos Limited and Sophos Group.
# All other product and company names mentioned are trademarks or registered trademarks of their
# respective owners.
#

module SophosCloud
  module CommonHelper

    def common_account ()
      return node[:sophos_cloud][:environment].downcase
    end

    def common_application_name ()
      return node[:sophos_cloud][:application_name].downcase
    end

    def common_cookbook_install_dir (cookbook_name_param = nil)
      cookbook_name_param = cookbook_name if cookbook_name_param.nil?

      return "#{common_install_dir}/#{cookbook_name_param}/#{common_cookbook_version}"
    end

    def common_cookbook_log_dir (cookbook_name_param = nil)
      cookbook_name_param = cookbook_name if cookbook_name_param.nil?

      return "#{common_log_dir}/#{cookbook_name_param}"
    end

    def common_cookbook_version ()
      return run_context.cookbook_collection[cookbook_name].metadata.version.to_s
    end

    def common_dns_name (name)
      return "#{name}.#{common_vpc_name.downcase}.#{common_region}.#{common_account}.hydra.sophos.com"
    end

    def common_docker_registry ()
      ret_val = node[:sophos_cloud_common][:docker_registry]
      raise 'Unknown docker registry' if ret_val.nil?

      return ret_val
    end

    def common_hostname ()
      ret_val = node[:ec2][:hostname]
      raise 'Unknown hostname' if ret_val.nil?

      return ret_val
    end

    def common_install_dir ()
      ret_val = node[:sophos_cloud_common][:install_dir]
      raise 'Unknown install directory' if ret_val.nil?

      return ret_val
    end

    def common_instance_id ()
      ret_val = node[:ec2][:instance_id]
      raise 'Unknown instance_id' if ret_val.nil?

      return ret_val
    end

    def common_log_dir ()
      ret_val = node[:sophos_cloud_common][:log_dir]
      raise 'Unknown log directory' if ret_val.nil?

      return ret_val
    end

    def common_region ()
      return node[:ec2][:placement_availability_zone].chop
    end

    def common_s3_bucket_region ()
      ret_val = node[:sophos_cloud][:s3_bucket_region]
      raise 'Unknown s3 bucket region' if ret_val.nil?

      return ret_val
    end

    def common_thirdparty_bucket ()
      # During ami baking the value is prepended with '//'
      # Need to remove it
      return _private_common_preprocess_thirdparty_str()[0]
    end

    def common_thirdparty_bucket_leading_dir ()
      return _private_common_preprocess_thirdparty_str().drop(1).join('/')
    end

    def common_vpc_name ()
      ret_val = node[:sophos_cloud][:vpc_name]
      raise 'Unknown VPC name' if ret_val.nil?

      return ret_val
    end

    # Modules cannot really have private methods
    def _private_common_preprocess_thirdparty_str ()
      # During ami baking the value is prepended with '//'
      # Need to remove it
      thirdparty_bucket = node[:sophos_cloud][:thirdparty]

      raise 'Unknown thirdparty bucket' if thirdparty_bucket.nil?

      return thirdparty_bucket.split('/').drop_while { |cur| cur.empty? }
    end

  end
end
