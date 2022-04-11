/*
 * Copyright 2019 Sophos Limited. All rights reserved.
 *
 * 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of Sophos Limited and Sophos Group. All other product
 * and company names mentioned are trademarks or registered trademarks of their respective owners.
 */
var aws = require('aws-sdk');

exports.handler = (event, context, callback) => {
    var sesNotification = event.Records[0].ses;
    var namespace = null;

    const US_EAST_2_NAMESPACE = "xgemail-monitor-ms-us-east-2";
    const US_WEST_2_NAMESPACE = "xgemail-monitor-ms-us-west-2";
    const EU_CENTRAL_1_NAMESPACE = "xgemail-monitor-ms-eu-central-1";
    const EU_WEST_1_NAMESPACE = "xgemail-monitor-ms-eu-west-1";

    // obtain the time when it was received by SES
    var timeReceivedSes = new Date(sesNotification.mail.timestamp);

    var timeIntervalMillis = -1;

    var headersArray = sesNotification.mail.headers;

    // obtain the time when it was sent from the headers
    var timeSent = sesNotification.mail.commonHeaders.date;
    timeSent = new Date(timeSent);

    var namespaceMap = {
        "us-east-2.compute.internal": US_EAST_2_NAMESPACE,
        "us-west-2.compute.internal" : US_WEST_2_NAMESPACE,
        "eu-central-1.compute.internal": EU_CENTRAL_1_NAMESPACE,
        "eu-west-1.compute.internal": EU_WEST_1_NAMESPACE
    };

    outerloop:
        for(var i = 0; i < headersArray.length; i++) {
            var header = headersArray[i];
            if (header.name === 'Received') {
                for (var key in namespaceMap) {
                    if (header.value.includes(key)) {
                        namespace = namespaceMap[key];
                        break outerloop;
                    }
                }
            }
        }

    if (namespace === null) {
        throw new Error("Error identifying correct namespace");
    }

    // calculate time interval between sent and received
    timeIntervalMillis = timeReceivedSes - timeSent;
    console.log(sesNotification.mail.commonHeaders);
    console.log(`Namespace: ${namespace}\troundTripTime:${timeIntervalMillis}`);

    //Write this value to CloudWatch if the timeSent was obtained
    if (timeIntervalMillis > 0) {
        var params = {
            MetricData: [
                {
                    MetricName: 'message-roundtrip-time',
                    Dimensions: [
                        {
                            Name: 'roundTripTime',
                            Value: 'seconds'
                        },
                    ],

                    Timestamp: new Date(),
                    Unit: 'Milliseconds',
                    Value: timeIntervalMillis
                }
            ],
            Namespace: namespace
        };
    }
    else {
        var sentTimeNotFoundError = new Error("Error in obtaining sent timestamp");
        callback(sentTimeNotFoundError);
    }
};