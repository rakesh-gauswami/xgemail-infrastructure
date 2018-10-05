FROM alpine:latest

ENV JAVA_VERSION=${BUILD_JAVA_VERSION:-8} \
    JAVA_UPDATE=${BUILD_JAVA_UPDATE:-101} \
    JAVA_BUILD=${BUILD_JAVA_BUILD:-13} \
    JAVA_HOME="/usr/java"

RUN apk add --no-cache --virtual=build-dependencies wget ca-certificates && \
    cd "/tmp" && \
    wget http://maven.cloud.sophos/nexus/content/repositories/pulsar-files/content/thirdparty/alpine/glibc-2.25-r0.apk &&  \
    apk add --no-cache --allow-untrusted glibc-* libgcc && \
    wget https://nexus.sophos-tools.com/repository/build-assets/jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz && \
    tar -xzf "jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz" && \
    mv "/tmp/jdk1.${JAVA_VERSION}.0_${JAVA_UPDATE}" "/usr/java-${JAVA_VERSION}-oracle" && \
    ln -s "/usr/java-${JAVA_VERSION}-oracle" "$JAVA_HOME" && \
    ln -s "$JAVA_HOME/bin/"* "/usr/bin/" && \
    rm -rf "$JAVA_HOME/"*src.zip && \
    rm -rf "$JAVA_HOME/lib/missioncontrol" \
           "$JAVA_HOME/lib/visualvm" \
           "$JAVA_HOME/lib/"*javafx* \
           "$JAVA_HOME/jre/lib/plugin.jar" \
           "$JAVA_HOME/jre/lib/ext/jfxrt.jar" \
           "$JAVA_HOME/jre/bin/javaws" \
           "$JAVA_HOME/jre/lib/javaws.jar" \
           "$JAVA_HOME/jre/lib/desktop" \
           "$JAVA_HOME/jre/plugin" \
           "$JAVA_HOME/jre/lib/"deploy* \
           "$JAVA_HOME/jre/lib/"*javafx* \
           "$JAVA_HOME/jre/lib/"*jfx* \
           "$JAVA_HOME/jre/lib/amd64/libdecora_sse.so" \
           "$JAVA_HOME/jre/lib/amd64/"libprism_*.so \
           "$JAVA_HOME/jre/lib/amd64/libfxplugins.so" \
           "$JAVA_HOME/jre/lib/amd64/libglass.so" \
           "$JAVA_HOME/jre/lib/amd64/libgstreamer-lite.so" \
           "$JAVA_HOME/jre/lib/amd64/"libjavafx*.so \
           "$JAVA_HOME/jre/lib/amd64/"libjfx*.so && \
    apk  --no-cache del build-dependencies && \
    rm -rf "/tmp/"*

ENV CATALINA_HOME="/usr/local/tomcat"
ENV PATH="${CATALINA_HOME}/bin:${PATH}"

ENV TOMCAT_MAJOR_VERSION="8"
ENV TOMCAT_MINOR_VERSION="8.0.50"

ENV CATALINA_OPTS="$CATALINA_OPTS -server -Xms1024m -Xmx2048m -XX:PermSize=1024m -XX:MaxPermSize=1536m -Djava.net.preferIPv4Stack=true -Dspring.profiles.active=sandbox -agentlib:jdwp=transport=dt_socket,address=1043,server=y,suspend=n"

# INSTALL TOMCAT
RUN apk add --no-cache --virtual=build-dependencies wget ca-certificates openssl && \
    mkdir -p "/usr/local"; cd "/usr/local" ; \
    wget -q https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_MINOR_VERSION}/bin/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz	&& \
    wget -qO- https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_MINOR_VERSION}/bin/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz.sha512 | sha512sum -c - && \
    tar zxf apache-tomcat-*.tar.gz && \
    rm apache-tomcat-*.tar.gz && \
    mv apache-tomcat* tomcat

RUN [ "/bin/sh", "-c", "mkdir -p /etc/sophos" ]
RUN [ "/bin/sh", "-c", "mkdir -p /etc/sophos/ssl" ]
RUN [ "/bin/sh", "-c", "mkdir -p /usr/local/etc/sophos" ]

#copy server configurations
RUN apk add --no-cache libuuid libidn

COPY config/server.xml /usr/local/tomcat/conf/server.xml
COPY config/context.xml /usr/local/tomcat/conf/context.xml
COPY config/tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml
COPY config/context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml
COPY config/application.properties /usr/local/etc/sophos

#JDBC driver fix
RUN wget -q https://jdbc.postgresql.org/download/postgresql-42.2.2.jar -P ${CATALINA_HOME}/lib

EXPOSE 8080 1043
ADD run.sh /run.sh
CMD ["/bin/sh", "/run.sh"]
