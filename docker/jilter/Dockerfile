FROM 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/xgemail-java:latest

LABEL maintainer="Sophos Inc. <www.sophos.com>" \
      description="jilter-base service image"

ENV SPF_VERSION 1.2.10

RUN yum update -y && \
	yum install -y \
            epel-release \
            gcc-c++ \
            curl \
            initscripts \
            libspf2-${SPF_VERSION} libspf2-devel-${SPF_VERSION} \
            awscli && \
 	        yum clean all

ADD run.sh /opt/scripts/run.sh

RUN chmod 777 /opt/scripts/run.sh

RUN find . -type f -name 'libdkimjni*' -execdir mv {} libdkimjni.so \;
RUN find . -type f -name 'libspfjni*' -execdir mv {} libspfjni.so \;