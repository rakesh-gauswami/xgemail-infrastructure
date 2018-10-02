FROM 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/xgemail-base:latest

LABEL maintainer="Sophos Inc. <www.sophos.com>" \
      description="Postfix base image"

#Add files
ADD thirdparty /tmp
ADD run.sh /opt/run.sh

#Perform update
RUN yum clean all && \
    yum install -y epel-release && \
    yum localinstall -y /tmp/*.rpm && \
    yum install -y \
              cyrus-sasl \
              cyrus-sasl-plain \
              cyrus-imapd \
              python \
              python-pip && \
    rm -rf /var/cache/yum && \
    pip install --upgrade pip && \
    pip install boto3 argparse requests && \
    useradd -s /usr/sbin/nologin -r -M -d /dev/null messageprocessor
