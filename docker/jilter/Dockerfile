FROM 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/xgemail-java:latest

LABEL maintainer="Sophos Inc. <www.sophos.com>" \
      description="jilter-base service image"

# Get to the latest versions and Install and enable the EPEL repo, which is where the spf library lives
RUN yum update -y && \
	yum install -y \
            epel-release \
            gcc-c++ \
            curl \
            initscripts \
            awscli && \
	yum clean all && \
	mkdir -p /data/conf

ADD logback.xml /data/conf
