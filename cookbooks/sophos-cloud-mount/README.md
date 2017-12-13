sophos-cloud-mount
==================

Mounts devices and formats filesystems.


Recipes
-------

### default

Mounts a list of devices and formats the file system on each one.  EBS volumes 
in EC2 are assumed to be attached prior to running this recipe.  

Sample role configuration that mounts two devices to the paths /d0 and /d1 and 
formats an ext3 filesystem on each:
	
	"mount": {
		"volumes": [{
			"path": "/d0",
			"device": "/dev/sdb",
			"fs_type": "ext3",
            "mkfs_options": "-F -j -m 1 -O sparse_super,dir_index",
            "mount_options": "noatime,nodiratime"
		}, {
			"path": "/d1",
			"device": "/dev/sdc",
			"fs_type": "ext3",
            "mkfs_options": "-F -j -m 1 -O sparse_super,dir_index",
            "mount_options": "noatime,nodiratime"
		}]
	}
	
Additionally, the `umount` property can be set to `true` to ensure that a 
device is unmounted.  This feature is useful as some EC2 AMIs may be pre-baked 
with an ephermal device mounted to a specific path.

Sample role configuration that ensures the /dev/sdc device is unmounted before 
attempting to mount and format it:

	"mount": {
		"volumes": [{
			"path": "/mnt",
			"device": "/dev/sdc",
			"umount": true
		}, {
			"path": "/d0",
			"device": "/dev/sdc",
			"fs_type": "ext3",
            "mkfs_options": "-F -j -m 1 -O sparse_super,dir_index",
            "mount_options": "noatime,nodiratime"
		}]
	}
	
Volumes can be encrypted using LUKS by setting the `encrypted` property to 
`true` on each volume.  If a `kms_key_id` configuration property is present 
then AWS KMS service will be used to encrypt the LUKS password file stored on 
the root partition.  If `kms_key_id` is not present then the LUKS password will 
be stored in plaintext on the root volume.  Adding the `encrypted` property to 
a drive that was already mounted will have no effect.

Sample role configuration that encrypts /dev/sdb and uses AWS KMS to encrypt 
the password file.

	"mount": {
		"volumes": [{
			"path": "/d0",
			"device": "/dev/sdb",
			"encrypted": true,
			"kms_key_id": "some_kms_key_id",
			"kms_region": "us-west-2",
			"fs_type": "ext3",
            "mkfs_options": "-F -j -m 1 -O sparse_super,dir_index",
            "mount_options": "noatime,nodiratime"
		}]
	}
	