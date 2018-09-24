FROM 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/xgemail-java:latest

# Setup the environment
ENV SPF_VERSION 1.2.10
ENV DKIM_VERSION 2.11.0

# Get to the latest versions:
RUN yum update -y

# Install and enable the EPEL repo, which is where the spf library lives
RUN yum install -y epel-release
RUN yum-config-manager --enable epel

# Install libraries and tool chain needed for the build
RUN yum install -y libspf2-${SPF_VERSION} libspf2-devel-${SPF_VERSION} && \
yum install -y libopendkim-${DKIM_VERSION} libopendkim-devel-${DKIM_VERSION} && \
yum install -y gcc-c++ && \
yum install - curl && \
yum clean all
