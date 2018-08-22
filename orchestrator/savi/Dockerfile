FROM centos:latest

# variables
ARG INSTALL_DIR=/tmp/savi-install
ARG SAV_DIR=/usr/local/savdi
ARG SAV_SIG_DIR=/usr/local/sav
ARG SAV_LOG_DIR=/var/log/xgemail/savdid

ARG USER=SET05879
ARG PASSWORD=h44d63sr
ARG PROVIDED_SAV_FILE=savi-files-for-docker.tar.gz
ARG SAV_PACKAGE=linux.amd64.glibc.2.3.tar
ARG SAVDI_PACKAGE=savdi-linux-64bit.tar
ARG SAVDID_CONF_FILE=savdid.conf

# create required directories
RUN mkdir -p $INSTALL_DIR
RUN mkdir -p $SAV_DIR
RUN mkdir -p $SAV_SIG_DIR
RUN mkdir -p $SAV_LOG_DIR

# install required packages
RUN yum install -y \
    curl \
    file \
    python \
    wget \
    tar \
    unzip

# change work directory
WORKDIR "$INSTALL_DIR"

# copy file from host and extract
COPY $PROVIDED_SAV_FILE $INSTALL_DIR
RUN tar -xf $PROVIDED_SAV_FILE

# copy library and config file to appropriate location
COPY libssp.so.0 /usr/local/lib
COPY $SAVDID_CONF_FILE $SAV_DIR

# download IDE and VDL packages
RUN python sav-download.py -p $SAV_PACKAGE -U $USER -P $PASSWORD

RUN unzip -o vdl.zip -d $INSTALL_DIR/sav-install
RUN unzip -o ide_*.zip -d $SAV_SIG_DIR/

RUN tar xf $SAV_PACKAGE -C $INSTALL_DIR
RUN tar xf $SAVDI_PACKAGE -C $INSTALL_DIR

# install SAV and SAVDI
RUN $INSTALL_DIR/sav-install/install.sh
RUN $INSTALL_DIR/savdi-install/savdi_install.sh

RUN cp -f $INSTALL_DIR/savdi-install/savdid /usr/sbin/

# open SAV-DI scan port to host - set in docker-compose.yml file
#EXPOSE 4010

# Run the SAV-DI daemon when the container is run
CMD /usr/sbin/savdid -s -f /var/run/savdid.pid -c /usr/local/savdi/savdid.conf
