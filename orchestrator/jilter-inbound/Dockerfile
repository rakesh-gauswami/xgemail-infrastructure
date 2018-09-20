FROM 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/xgemail-java:latest

RUN mkdir -p /data/scripts && \
    mkdir -p /data/conf

ADD startup.sh /data/scripts
RUN chmod 777 /data/scripts/startup.sh

ADD jilter-application.properties /data/conf

ENTRYPOINT ["/data/scripts/startup.sh"]


