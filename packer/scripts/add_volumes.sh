#!/bin/bash
# Install the additional volumes
echo '/dev/xvdf  /data           ext4    defaults      0   0' >> /etc/fstab
echo '/dev/xvdg  /var            ext4    defaults      0   0' >> /etc/fstab
echo '/dev/xvdh  /tmp            ext4    defaults,noexec,nosuid      0   0' >> /etc/fstab
echo 'updated /etc/fstab'
mkfs -t ext4 /dev/xvdf
mkfs -t ext4 /dev/xvdg
mkfs -t ext4 /dev/xvdh
echo 'created file systems'
mkdir /data
echo 'created /data directory'
mount /dev/xvdg /mnt
cp -rp /var/* /mnt
umount /mnt
echo 'copied contents of /var'
mount /dev/xvdh /mnt
cp -rp /tmp/* /mnt
cp -rp /tmp/.ICE* /mnt
umount /mnt
echo 'copied contents of /tmp'
mount -a
echo 'mounted new file systems'
chmod 777 /tmp
chmod a+t /tmp
mkdir /data/log
echo 'completed add_volumes'
