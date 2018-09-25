FROM 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/xgemail-java:latest

LABEL maintainer="Sophos Inc. <www.sophos.com>" \
      description="jilter-base service image"

# Setup the environment
ENV SPF_VERSION 1.2.10
ENV DKIM_VERSION 2.11.0

# Get to the latest versions and Install and enable the EPEL repo, which is where the spf library lives
RUN yum update -y && \
	yum install -y epel-release && \
	yum-config-manager --enable epel &&\
	yum install -y libspf2-${SPF_VERSION} libspf2-devel-${SPF_VERSION} && \
	yum install -y libopendkim-${DKIM_VERSION} libopendkim-devel-${DKIM_VERSION} && \
	yum install -y gcc-c++ && \
	yum install - curl && \
	yum clean all
