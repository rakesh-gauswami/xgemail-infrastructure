FROM centos:latest

# variables
ARG USER=filter
ARG INSTALL_DIR=/tmp/cyren-install
ARG CTASD_DIR=/usr/lib/ctasd
ARG SNMP_DIR="${CTASD_DIR}/snmp"
ARG ETC_DIR=/etc/ctasd

ARG VERSION=5.00.0085
ARG PROVIDED_CTASD_FILE="ctasd-${VERSION}-linux-x86_64.tar.gz"
ARG CONF_FILE=ctasd.conf

# create required directories
RUN mkdir -p $INSTALL_DIR
RUN mkdir -p $SNMP_DIR
RUN mkdir -p $ETC_DIR

# install required packages
RUN yum install -y \
    wget \
    tar \
    net-snmp-perl \
    perl-Time-HiRes \
    perl-Sys-Syslog

# create user under which CYREN will run
RUN useradd -r $USER

# change work directory
WORKDIR "$INSTALL_DIR"

# copy file from host and extract
COPY $PROVIDED_CTASD_FILE $INSTALL_DIR
COPY $CONF_FILE $ETC_DIR

# extract ctasd file
RUN tar -xf $PROVIDED_CTASD_FILE

# copy binaries to proper location
RUN cp -f  "ctasd-${VERSION}-linux-x86_64/bin/ctasd" $CTASD_DIR
RUN cp -f  "ctasd-${VERSION}-linux-x86_64/bin/ctasd.bin" $CTASD_DIR
RUN cp -f  "ctasd-${VERSION}-linux-x86_64/bin/"*.so $CTASD_DIR
RUN cp -rf "ctasd-${VERSION}-linux-x86_64/bin/snmp/"* $SNMP_DIR

# cleanup
RUN rm -rf "ctasd-${VERSION}-linux-x86_64"
RUN rm -f $PROVIDED_CTASD_FILE

# open CYREN scan port to host - set in docker-compose.yml file
#EXPOSE 8088

# Run CYREN in interactive mode (-i)
CMD /usr/lib/ctasd/ctasd.bin -i -l /usr/lib/ctasd -c /etc/ctasd/ctasd.conf
