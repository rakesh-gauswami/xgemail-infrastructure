FROM 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/jilter-base:latest

LABEL maintainer="Sophos Inc. <www.sophos.com>" \
      description="jilter-outbound service image"

RUN mkdir -p /data/scripts && \
    mkdir -p /data/conf

ADD startup.sh /data/scripts
RUN chmod 777 /data/scripts/startup.sh

ADD jilter-application.properties /data/conf
ADD logback.xml /data/conf

ENTRYPOINT ["/data/scripts/startup.sh"]


