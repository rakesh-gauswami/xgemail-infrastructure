/*
 * Copyright 2017 Sophos Limited. All rights reserved.
 *
 * 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of Sophos Limited and Sophos Group. All other product
 * and company names mentioned are trademarks or registered trademarks of their respective owners.
 */

 //Send email to predetermined recipients located in different regions from us-west-2.
 //Email is sent as often as specified in AWS trigger for this job.

var aws = require('aws-sdk');

//Sending from us-west-2
var ses = new aws.SES({
    region: 'us-west-2'
});

exports.handler = (event, context, callback) => {
    var date = new Date().toISOString();
    console.log('Incoming: ', event);
    //Domains for mailboxes are already verified in AWS otherwise sending email will result in error.
    var mailboxes= [
        'us.east.2.prod@sophos-email-monitor.us',
        'us.west.2.prod@sophos-email-monitor.com',
        'eu.west.1.prod@sophos-email-monitor.org',
        'eu.central.1.prod@sophos-email-monitor.net'
    ];

    var index_mailboxes = 0;
    for(; index_mailboxes < mailboxes.length; index_mailboxes++) {
        var recipient = mailboxes[index_mailboxes];
        var emailParams = {
            Destination: {
                ToAddresses: [recipient]
            },
            Message: {
                Body: {
                    Text: {
                        Data: ''
                    }
                },
                Subject: {
                    Data: 'Sophos Email Monitor ' + date
                }
            },
            Source: 'monitor.sender@sophos-email-monitor.com'
        };
        console.log('Sending email to ', recipient);
        // Send email via AWS-SDK API.
        ses.sendEmail(emailParams, function(err,data) {
            if(err) {
                console.log('Error encountered while sending email', err);
            }
            else {
                console.log('Email Sent');
                console.log(data);
                context.succeed(event);
            }
        });
    }
};