## Installation and management of software
Cmnd_Alias SOFTWARE = /bin/rpm, /usr/bin/up2date, /usr/bin/yum

## Services
Cmnd_Alias SERVICES = /sbin/service, /sbin/chkconfig

## Updating the locate database
Cmnd_Alias LOCATE = /usr/bin/updatedb

## Storage
Cmnd_Alias STORAGE = /sbin/fdisk, /sbin/sfdisk, /sbin/parted, /sbin/partprobe, /bin/mount, /bin/umount

## Delegating permissions
Cmnd_Alias DELEGATING = /usr/sbin/visudo, /bin/chown, /bin/chmod, /bin/chgrp

## Processes
Cmnd_Alias PROCESSES = /bin/nice, /bin/kill, /usr/bin/kill, /usr/bin/killall

# Group rules for remote users
%remote_users ALL=(ALL) NOPASSWD:SOFTWARE, SERVICES, STORAGE, DELEGATING, PROCESSES, LOCATE