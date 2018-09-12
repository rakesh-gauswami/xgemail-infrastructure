FROM 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/xgemail-base:latest

LABEL maintainer="Sophos Inc. <www.sophos.com>" \
      description="Savi service image"

# variables
ARG INSTALL_DIR=/tmp/savi-install
ARG SAV_DIR=/usr/local/savdi
ARG SAV_SIG_DIR=/usr/local/sav
ARG SAV_LOG_DIR=/var/log/xgemail/savdid

# user/password -we need to set somewhere in order for sync to download
# latest vdl
ARG USER=SET05879
ARG PASSWORD=h44d63sr

ARG SAV_PACKAGE=linux.amd64.glibc.2.3.tar
ARG SAVDI_PACKAGE=savdi-linux-64bit.tar
ARG SAVDID_CONF_FILE=savdid.conf

# create required directories
RUN mkdir -p $INSTALL_DIR && \
		mkdir -p $SAV_DIR && \
		mkdir -p $SAV_SIG_DIR && \
		mkdir -p $SAV_LOG_DIR && \
		yum install -y \
    curl \
    file \
    python \
    unzip \
    wget \
    tar

# copy library and config file to appropriate location
COPY $SAVDI_PACKAGE $INSTALL_DIR
COPY libssp.so.0 /usr/local/lib
COPY $SAVDID_CONF_FILE $SAV_DIR
COPY sav-download.py $INSTALL_DIR

# change work directory
WORKDIR $INSTALL_DIR

# download IDE and VDL packages
RUN python $INSTALL_DIR/sav-download.py -p $SAV_PACKAGE -U $USER -P $PASSWORD &&\
		unzip -o vdl.zip -d $INSTALL_DIR/sav-install && \
		unzip -o ide_*.zip -d $SAV_SIG_DIR/ &&\
		tar xf $SAV_PACKAGE -C $INSTALL_DIR && \
		tar xf $SAVDI_PACKAGE -C $INSTALL_DIR && \
		$INSTALL_DIR/sav-install/install.sh && \
    $INSTALL_DIR/savdi-install/savdi_install.sh && \
		cp -f $INSTALL_DIR/savdi-install/savdid /usr/sbin/

ENTRYPOINT ["sh", "-c", "/usr/sbin/savdid -s -f /var/run/savdid.pid -c /usr/local/savdi/savdid.conf"]
