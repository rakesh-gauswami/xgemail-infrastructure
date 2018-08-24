FROM centos:7

LABEL maintainer="Sophos Inc. <www.sophos.com>"
LABEL description="Sandbox base image"

ENV container docker

RUN yum -y update \
  && yum install -y \
            logrotate \
            patch \
            rsyslog \
  && rm -rf /var/cache/yum 

VOLUME ["/sys/fs/cgroup"]
VOLUME ["/run"]

ENTRYPOINT ["/usr/sbin/init"]
