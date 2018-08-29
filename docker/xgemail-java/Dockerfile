FROM xgemail-base

LABEL maintainer="Sophos Inc. <www.sophos.com>" \
      description="Postfix JDK base image"

ENV JAVA_VERSION=${BUILD_JAVA_VERSION:-8} \
    JAVA_UPDATE=${BUILD_JAVA_UPDATE:-101} \
    JAVA_BUILD=${BUILD_JAVA_BUILD:-13} \
    JAVA_HOME="/usr/java"

COPY jce_policy-8.zip /tmp/jce_policy-8.zip

RUN yum update -y && \
    yum install -y wget unzip && \
    cd "/tmp" && \
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
    unzip "jce_policy-${JAVA_VERSION}.zip" && \
    mv "UnlimitedJCEPolicyJDK${JAVA_VERSION}/US_export_policy.jar" "${JAVA_HOME}/jre/lib/security/" && \
    mv "UnlimitedJCEPolicyJDK${JAVA_VERSION}/local_policy.jar" "${JAVA_HOME}/jre/lib/security/" && \
    rm -rf /var/cache/yum && \
    rm -rf "/tmp/"*

CMD ["/bin/bash"]
