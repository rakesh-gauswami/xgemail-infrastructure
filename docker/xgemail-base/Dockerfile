FROM centos:7

LABEL maintainer="Sophos Inc. <www.sophos.com>" \
      description="Sandbox base image"

RUN yum -y update && \
    yum install -y \
            wget \
            unzip \
            logrotate \
            patch \
            rsyslog && \
    rm -rf /var/cache/yum && \
    cd "/tmp" && \
    wget https://packages.chef.io/files/stable/chef/12.3.0/el/6/chef-12.3.0-1.el6.x86_64.rpm && \
    rpm -ivh chef-12.3.0-1.el6.x86_64.rpm && \
    wget https://rubygems.org/gems/aws-sdk/versions/3.0.1 && \
    /opt/chef/embedded/bin/gem install aws-sdk && \
    rm -rf "/tmp/"*

VOLUME ["/sys/fs/cgroup"]
VOLUME ["/run"]

ENTRYPOINT ["/usr/sbin/init"]
