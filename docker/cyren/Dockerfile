FROM 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/xgemail-base:latest

LABEL maintainer="Sophos Inc. <www.sophos.com>" \
      description="Cyren service image"

# variables
ARG USER=filter
ARG INSTALL_DIR=/tmp/cyren-install
ARG CTASD_DIR=/usr/lib/ctasd
ARG SNMP_DIR="${CTASD_DIR}/snmp"
ARG ETC_DIR=/etc/ctasd
ARG VERSION=5.01.0006.4
ARG PROVIDED_CTASD_FILE="ctasd-${VERSION}-linux-x86_64.tar.gz"
ARG CONF_FILE=ctasd.conf

# create required directories
RUN mkdir -p $INSTALL_DIR && \
    mkdir -p $SNMP_DIR && \
    mkdir -p $ETC_DIR && \
    yum install -y \
    net-snmp-perl \
    perl-Time-HiRes \
    perl-Sys-Syslog && \
    useradd -r $USER

# copy file from host and extract
COPY $PROVIDED_CTASD_FILE $INSTALL_DIR
COPY $CONF_FILE $ETC_DIR

# change work directory
RUN cd $INSTALL_DIR && \
    tar -xf $INSTALL_DIR/$PROVIDED_CTASD_FILE && \
    cp -f  "ctasd-${VERSION}-linux-x86_64/bin/ctasd" $CTASD_DIR && \
    cp -f  "ctasd-${VERSION}-linux-x86_64/bin/ctasd.bin" $CTASD_DIR && \
    cp -f  "ctasd-${VERSION}-linux-x86_64/bin/"*.so $CTASD_DIR && \
    cp -rf "ctasd-${VERSION}-linux-x86_64/bin/snmp/"* $SNMP_DIR && \
    rm -rf "ctasd-${VERSION}-linux-x86_64" && \
    rm -f $PROVIDED_CTASD_FILE

# Run CYREN in interactive mode (-i)
ENTRYPOINT ["sh", "-c", "/usr/lib/ctasd/ctasd.bin -i -l /usr/lib/ctasd -c /etc/ctasd/ctasd.conf"]
