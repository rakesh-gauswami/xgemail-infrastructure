#
# Cookbook Name:: sophos-cloud-mount
# Recipe:: default
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

#--------------------------------------------------------------------------------
# DIRECTORIES
#--------------------------------------------------------------------------------
directory node[:mount][:luks_password_dir] do
  owner "root"
  group "root"
  mode 0755
end

#--------------------------------------------------------------------------------
# VOLUMES
#--------------------------------------------------------------------------------
node[:mount][:volumes].each do |volume|
  
  device_name = volume[:device].split('/')[-1]
  device_encrypted_name = "#{device_name}_crypt"
  device_mapped_path = volume[:encrypted] ? "/dev/mapper/#{device_encrypted_name}" : volume[:device]
  mounted = File.readlines("/proc/mounts").grep(/#{volume[:path]}/).size > 0
  password_file = "#{node[:mount][:luks_password_dir]}/.sophos-#{device_name}-luks"
  
  if volume[:umount]
	#---------------------------------------------------------------------------
	# UNMOUNT
	#---------------------------------------------------------------------------
    mount volume[:path] do
      device device_mapped_path
      action :umount
    end
  else
    #-------------------------------------------------------------------------
    # ENCRYPT
    #-------------------------------------------------------------------------
    bash "create password file" do
      user "root"
      environment(
        "KMS_KEY_ID" => volume[:kms_key_id] || '',
        "KMS_REGION" => volume[:kms_region] || '',
        "PASSWORD_FILE" => password_file
      )
      code <<-EOH
      PASSPHRASE=$(< /dev/urandom tr -dc '_A-Za-z0-9!@#%^' | head -c 256 | xargs -0 echo)
      if [ "${KMS_KEY_ID}" ]; then
        aws --region ${KMS_REGION} kms encrypt --key-id ${KMS_KEY_ID} --plaintext "${PASSPHRASE}" --query CiphertextBlob --output text | base64 -d > ${PASSWORD_FILE}
      else
        echo "${PASSPHRASE}" > ${PASSWORD_FILE}
      fi
      chmod 400 ${PASSWORD_FILE}
      unset PASSPHRASE
      EOH
      not_if { File.exists?(password_file) }
      only_if { volume[:encrypted] }
    end
    
    #-------------------------------------------------------------------------
    bash "encrypt device" do
      user "root"
      environment(
        "DEVICE" => volume[:device],
        "DEVICE_ENCRYPTED_NAME" => device_encrypted_name,
        "KMS_KEY_ID" => volume[:kms_key_id] || '',
        "KMS_REGION" => volume[:kms_region]  || '',
        "PASSWORD_FILE" => password_file
      )
      code <<-EOH
      if [ "${KMS_KEY_ID}" ]; then
        PASSPHRASE=$(aws --region ${KMS_REGION} kms decrypt --ciphertext-blob fileb://${PASSWORD_FILE} --output text --query Plaintext | base64 -d)
      else
        PASSPHRASE=$(cat ${PASSWORD_FILE})
      fi
      echo "${PASSPHRASE}" | cryptsetup luksFormat ${DEVICE}
      UUID=$(cryptsetup luksUUID ${DEVICE})
      echo "${PASSPHRASE}" | cryptsetup luksOpen UUID=${UUID} ${DEVICE_ENCRYPTED_NAME}
      unset PASSPHRASE
      EOH
      not_if { mounted or (`cryptsetup luksUUID #{volume[:device]}`.length > 0 rescue false) }
      only_if { volume[:encrypted] }
    end
    
    #---------------------------------------------------------------------------
    template "/etc/init.d/luks-mount-#{device_name}" do
      owner "root"
      group "root"
      source "luks-mount.init.erb"
      mode 0755
      variables(
        "device_encrypted_name" => device_encrypted_name,
        "device_name" => device_name,
        "device_path" => volume[:device],
        "kms_key_id" => volume[:kms_key_id],
        "kms_region" => volume[:kms_region],
        "mount_options" => volume[:mount_options],
        "path" => volume[:path],
        "password_file" => password_file
      )
      only_if { volume[:encrypted] }
    end
    
    #---------------------------------------------------------------------------
    link "/etc/rc2.d/S20luks-mount-#{device_name}" do
      action :create
      link_type :symbolic
      to "/etc/init.d/luks-mount-#{device_name}"
      owner "root"
      group "root"
      only_if { volume[:encrypted] }
    end
    
    # TODO: There is an additional step neeed for the AWS Linux AMI regarding dracut.
    # See https://www.whaletech.co/2016/04/07/encryption-ephemeral-volumes-with-kms.html
    
	#---------------------------------------------------------------------------
	# MOUNT
	#---------------------------------------------------------------------------
    execute "mkfs" do
	  not_if { mounted }
      command "mkfs.#{volume[:fs_type]} #{volume[:mkfs_options]} #{device_mapped_path}"
    end
    
	#---------------------------------------------------------------------------
    execute "mkdir -m 755 -p #{volume[:path]}" do
      not_if { File.exists?(volume[:path]) }
      command "mkdir -m 755 -p #{volume[:path]}"
    end
  
	#---------------------------------------------------------------------------
    mount volume[:path] do
   	  device device_mapped_path
      fstype volume[:fs_type]
      options volume[:mount_options]
      action volume[:encrypted] ? :mount : [ :mount, :enable ]
    end
  end
end
