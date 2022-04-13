/*
 * Copyright 2019 Sophos Limited. All rights reserved.
 *
 * 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of Sophos Limited and Sophos Group. All other product
 * and company names mentioned are trademarks or registered trademarks of their respective owners.
 */

//Send email to predetermined recipients located in different regions from us-west-2.
//Email is sent as often as specified in AWS trigger for this job.

var aws = require('aws-sdk');

//Sending from SES region
var ses = new aws.SES({
    region: process.env.XGEMAIL_SES_REGION
});

exports.handler = (event, context, callback) => {
    var date = new Date().toISOString();
    console.log('Incoming: ', event);
    //Domains for mailboxes are already verified in AWS otherwise sending email will result in error.
    var mailboxes= [
        process.env.XGEMAIL_EU_CENTRAL_1_MAILBOX_NAME,
        process.env.XGEMAIL_EU_WEST_1_MAILBOX_NAME,
        process.env.XGEMAIL_US_EAST_2_MAILBOX_NAME,
        process.env.XGEMAIL_US_WEST_2_MAILBOX_NAME
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
            Source: process.env.XGEMAIL_US_WEST_2_SENDER_MAILBOX_NAME
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