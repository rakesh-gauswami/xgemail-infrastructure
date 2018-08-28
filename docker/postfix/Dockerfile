FROM xgemail-base 

LABEL maintainer="Sophos Inc. <www.sophos.com>" \
      description="Postfix base image"
 
RUN mkdir -p /var/lib/xgemail/thirdparty

#Add files
ADD rsyslog.conf /etc/rsyslog.conf
Add etc/sysconfig/network /etc/sysconfig/network
ADD postfix.sh /etc/init.d/postfix3-sophos
ADD thirdparty /var/lib/xgemail/thirdparty

#Perform update
RUN yum clean all && \
    yum install -y epel-release && \
    yum localinstall -y /var/lib/xgemail/thirdparty/*.rpm && \
    yum install -y \
              cyrus-sasl \
              cyrus-sasl-plain \
              cyrus-imapd \
              python \
              python-pip && \
    rm -rf /var/cache/yum && \
    pip install --upgrade pip && \
    pip install boto3 argparse

RUN chkconfig --add postfix3-sophos && \
    chkconfig --level 2345 postfix3-sophos on