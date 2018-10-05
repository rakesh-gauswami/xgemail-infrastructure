FROM 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/xgemail-java:latest

LABEL maintainer="Sophos Inc. <www.sophos.com>" \
      description="jilter-base service image"

RUN yum update -y && \
	yum install -y \
            epel-release \
            gcc-c++ \
            curl \
            initscripts \
            awscli && \
	yum clean all

ADD run.sh /opt/run.sh

RUN chmod 777 /data/scripts/startup.sh

ENTRYPOINT ["/data/scripts/startup.sh"]
