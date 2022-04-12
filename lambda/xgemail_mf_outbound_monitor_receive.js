/*
 * Copyright 2019 Sophos Limited. All rights reserved.
 *
 * 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of Sophos Limited and Sophos Group. All other product
 * and company names mentioned are trademarks or registered trademarks of their respective owners.
 */
var aws = require('aws-sdk');

const US_EAST_2_NAMESPACE = "xgemail-mf-outbound-monitor-us-east-2";
const US_WEST_2_NAMESPACE = "xgemail-mf-outbound-monitor-us-west-2";
const EU_CENTRAL_1_NAMESPACE = "xgemail-mf-outbound-monitor-eu-central-1";
const EU_WEST_1_NAMESPACE = "xgemail-mf-outbound-monitor-eu-west-1";
const US_EAST_2_DOMAINNAME =  process.env.XGEMAIL_US_EAST_2_HOSTED_ZONE_NAME;
const US_WEST_2_DOMAINNAME =  process.env.XGEMAIL_US_WEST_2_HOSTED_ZONE_NAME;
const EU_CENTRAL_1_DOMAINNAME =  process.env.XGEMAIL_EU_CENTRAL_1_HOSTED_ZONE_NAME;
const EU_WEST_1_DOMAINNAME =  process.env.XGEMAIL_EU_WEST_1_HOSTED_ZONE_NAME;

const NAMESPACEMAP = {};
NAMESPACEMAP[US_EAST_2_DOMAINNAME] = US_EAST_2_NAMESPACE;
NAMESPACEMAP[US_WEST_2_DOMAINNAME] = US_WEST_2_NAMESPACE;
NAMESPACEMAP[EU_CENTRAL_1_DOMAINNAME] = EU_CENTRAL_1_NAMESPACE;
NAMESPACEMAP[EU_WEST_1_DOMAINNAME] = EU_WEST_1_NAMESPACE;

exports.handler = (event, context, callback) => {
    var sesNotification = event.Records[0].ses;
    var namespace = null;

    // obtain the time when it was received by SES
    var timeReceivedSes = new Date(sesNotification.mail.timestamp);

    var timeIntervalMillis = -1;

    var headersArray = sesNotification.mail.headers;

    // obtain the time when it was sent from the headers
    var timeSent = new Date(sesNotification.mail.commonHeaders.date);
    var emailSubject = sesNotification.mail.commonHeaders.subject;

    outerloop:
        for(var i = 0; i < headersArray.length; i++) {
            var header = headersArray[i];
            if (header.name === 'Return-Path') {
                for (var key in NAMESPACEMAP) {
                    if (header.value.includes(key)) {
                        namespace = NAMESPACEMAP[key];
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
    console.log(`Email with subject <${emailSubject}> arrived at <${timeReceivedSes}> and was sent at <${timeSent}>`);
    console.log(`Namespace: ${namespace}\troundTripTime:${timeIntervalMillis}`);

    //Write this value to CloudWatch if the timeSent was obtained
    if (timeIntervalMillis > 0) {
        var params = {
            MetricData: [
                {
                    MetricName: 'outbound-message-roundtrip-time',
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

    callback(null, 'Xgemail MailFlow Outbound Monitor Receive Lambda Triggered');
};
