postfix Docker Image
============================

Requirements
------------

#### Local Filesystem Mounts
- `/opt/sophos/xgemail/sqs-message-processor:/opt/sophos/xgemail/sqs-message-processor:rw` - MessageProcessor python source.
- `~/g/email/xgemail-infrastructure/docker/postfix/etc/postfix-is:/etc/postfix-is:rw` - Postfix instance configurations.
- `~/g/email/xgemail-infrastructure/docker/postfix/etc/ssl:/etc/ssl:ro` - Postfix SSL certs.

Build Process
----------
Postfix Image requires Sophos maintained postfix RPM to be available while building.
Please refer [postfix3-sophos](https://git.cloud.sophos/projects/EMAIL/repos/thirdparty/browse/postfix3-sophos) to build postfix RPM.

Usage
-----
Run build.sh script
./build.sh