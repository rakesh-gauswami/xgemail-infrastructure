@test "Encrypted drive is mounted" {
	grep /dev/mapper/sdb_crypt /proc/mounts
}

@test "Unencrypted drive is mounted" {
	grep /dev/sdc /proc/mounts
}
