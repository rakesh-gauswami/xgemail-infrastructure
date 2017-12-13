#
# Cookbook Name:: sophos-cloud-mount
# Recipe:: update
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

VOLUME_MOUNT_POINT = node["volumes"]["volume_mount_point"]

updates = {}

ruby_block "determine_if_update_is_needed" do
  block do
    require "json"

    new_mount = node["mount"]
    new_volumes = node["volumes"]

    # Read current settings from the file we wrote onto the volume.

    volume_mount_point = new_volumes["volume_mount_point"]
    volume_info_path = volume_mount_point + "/config/volume-info.json"
    volume_info_file = File.read(volume_info_path)
    old = JSON.parse(volume_info_file)

    # Get old and new values.

    old_volume_set_id = old["volume_set_id"]
    new_volume_set_id = new_volumes["volume_set_id"]

    old_sdb_domain = old["volume_tracker_sdb_domain"]
    new_sdb_domain = new_volumes["volume_tracker_sdb_domain"]

    old_iops = old["volume_iops_per_gb"].to_i
    new_iops = new_mount["volume_iops_per_gb"].to_i

    old_data_gb = old["volume_min_size_data_gb"].to_i
    new_data_gb = new_mount["volume_min_size_data_gb"].to_i

    # Log requested changes.

    Chef::Log.info("Check old_volume_set_id: '#{old_volume_set_id}'")
    Chef::Log.info("Check new_volume_set_id: '#{new_volume_set_id}'")

    Chef::Log.info("Check old_sdb_domain: '#{old_sdb_domain}'")
    Chef::Log.info("Check new_sdb_domain: '#{new_sdb_domain}'")

    Chef::Log.info("Check old_iops: '#{old_iops}'")
    Chef::Log.info("Check new_iops: '#{new_iops}'")

    Chef::Log.info("Check old_data_gb: '#{old_data_gb}'")
    Chef::Log.info("Check new_data_gb: '#{new_data_gb}'")

    # The only update we can perform on a running system is adding volumes
    # to a volume set.  All other changes require changing the volumes in a
    # volume set or changing which volume set we use.  These other changes
    # all require detaching volumes from the instance, which is prone to
    # hanging with the volumes stuck in the "busy" state.

    forbidden_updates = []

    if new_volume_set_id != old_volume_set_id
      forbidden_updates << "volume_set_id"
    end

    if new_sdb_domain != old_sdb_domain
      forbidden_updates << "volume_tracker_sdb_domain"
    end

    forbidden_updates.each do |setting|
      Chef::Log.warn("Changing #{setting} requires volume set switch and instance termination")
    end

    if forbidden_updates.empty?
      if new_iops != old_iops
        forbidden_updates << "volume_iops_per_gb"
      end

      forbidden_updates.each do |setting|
        Chef::Log.warn("Changing #{setting} requires a fresh volume set or volume replacement via snapshot")
      end

      if forbidden_updates.empty?
        if new_data_gb > old_data_gb
          # TODO CPLAT-6905 ;;; Remove next line once we support multiple volumes.
          Chef::Log.warn("Changing volume_min_size_data_gb not yet implemented")
        end
      end
    end

    updates.each do |k, vs|
      Chef::Log.info("Updated #{k} from #{vs[0]} to #{vs[1]}")
    end
  end
end

bash "apply updates to volume set" do
  # Yes, we intended to run the sync command twice.  Gordon recommends
  # we call it once to sync page cache to journal, then again to sync
  # the journal to final storage.  Gordon says the second sync could
  # be skipped as it's a paranoid hangover from a bug in the VFS layer
  # from some time back.  But it doesn't cost much, so be safe.
  user "root"
  code <<-EOH
    sync
    sync
    /root/bin/manage-ebs-volumes.py update --verbose
  EOH
  only_if { updates.length > 0 }
end
