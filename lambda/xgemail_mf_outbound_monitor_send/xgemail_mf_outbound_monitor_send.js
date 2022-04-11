/*
 * Copyright 2019 Sophos Limited. All rights reserved.
 *
 * 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of Sophos Limited and Sophos Group. All other product
 * and company names mentioned are trademarks or registered trademarks of their respective owners.
 */

var queryString = require('querystring');
var https = require('https');
var tokenModule = require('./create_json_web_token');
var tokenUnitTestModule = require('./unit_tests/create_json_web_token_unit_test');
var uuid = require('uuid');


// access token request constants
const SCOPE = 'https://graph.microsoft.com/.default';
const GRANT_TYPE = 'client_credentials';
const CLIENT_ASSERTION_TYPE = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer';
const ACCESS_TOKEN_HOST = 'login.microsoftonline.com';
const TENANT_ID = process.env.XGEMAIL_TENANT_ID;
const ACCESS_TOKEN_PATH = `/${TENANT_ID}/oauth2/v2.0/token`;
const US_WEST_2_RECIPIENT_DOMAIN = process.env.XGEMAIL_US_WEST_2_RECIPIENT_HOSTED_ZONE_NAME;

// send email constants
const SEND_EMAIL_HOST = 'graph.microsoft.com';

var regionalInfo = {};
regionalInfo['EUCENTRAL1'] = {'client_id': process.env.XGEMAIL_EU_CENTRAL_1_CLIENT_ID, 'sender_address': process.env.XGEMAIL_EU_CENTRAL_1_MAILBOX_NAME,
    'private_key_location': process.env.XGEMAIL_EU_CENTRAL_1_PRIVATE_KEY_LOCATION, 'public_key_thumbprint_location': process.env.XGEMAIL_EU_CENTRAL_1_PUBLIC_KEY_THUMBPRINT_LOCATION};
regionalInfo['USWEST2'] = {'client_id': process.env.XGEMAIL_US_WEST_2_CLIENT_ID, 'sender_address': process.env.XGEMAIL_US_WEST_2_MAILBOX_NAME,
    'private_key_location': process.env.XGEMAIL_US_WEST_2_PRIVATE_KEY_LOCATION, 'public_key_thumbprint_location': process.env.XGEMAIL_US_WEST_2_PUBLIC_KEY_THUMBPRINT_LOCATION};
regionalInfo['EUWEST1'] = {'client_id': process.env.XGEMAIL_EU_WEST_1_CLIENT_ID, 'sender_address': process.env.XGEMAIL_EU_WEST_1_MAILBOX_NAME,
    'private_key_location': process.env.XGEMAIL_EU_WEST_1_PRIVATE_KEY_LOCATION, 'public_key_thumbprint_location': process.env.XGEMAIL_EU_WEST_1_PUBLIC_KEY_THUMBPRINT_LOCATION};
regionalInfo['USEAST2'] = {'client_id': process.env.XGEMAIL_US_EAST_2_CLIENT_ID, 'sender_address': process.env.XGEMAIL_US_EAST_2_MAILBOX_NAME,
    'private_key_location': process.env.XGEMAIL_US_EAST_2_PRIVATE_KEY_LOCATION, 'public_key_thumbprint_location': process.env.XGEMAIL_US_EAST_2_PUBLIC_KEY_THUMBPRINT_LOCATION};

exports.handler = (event, context, callback) => {
    // for each region, obtain access token and send email
    for (var region in regionalInfo)
    {
        try
        {
            var clientID = regionalInfo[region]['client_id'];
            var senderAddress = regionalInfo[region]['sender_address'];
            var privateKeyLocation = regionalInfo[region]['private_key_location'];
            var publicKeyThumbprintLocation = regionalInfo[region]['public_key_thumbprint_location'];


            // get JWT token and if received successfully, make call to get access token and send email
            tokenModule.createToken(clientID, TENANT_ID, region, senderAddress, privateKeyLocation, publicKeyThumbprintLocation)
                .then(function(results) {
                    console.log(`JWT token successfully obtained for senderAddress <${results.senderAddress}>`);
                    getAccessTokenAndSendMail(results.clientID, results.token, results.senderAddress, results.region);
                }, function(errorMsg) {
                    console.log(`!!!!!failed to obtain jwt token for ${senderAddress}: errorMessage: ${errorMsg}`);
                });
        }
        catch (exception)
        {
            console.log(exception);
        }
    }

    // run create_json_web_token_unit_tests
    try
    {
        tokenUnitTestModule.testCreateX5TValue();
    }
    catch (exception)
    {
        console.log(`!!!!![unit_test]exception thrown while unit testing createX5T value: ${exception}`);
    }

    try
    {
        tokenUnitTestModule.testCreateToken();
    }
    catch (exception)
    {
        console.log(`!!!!![unit_test]exception thrown while unit testing createToken : ${exception}`);
    }

    callback(null, 'xgemail outbound lambda triggered');
};

//retrieve an access token from O365 and send email with it
function getAccessTokenAndSendMail(client_id, jwtToken, senderAddress, region) {
    var accessTokenPostData = queryString.stringify({
        'client_id': client_id,
        'scope': SCOPE,
        'grant_type': GRANT_TYPE,
        'client_assertion_type': CLIENT_ASSERTION_TYPE,
        'client_assertion': jwtToken
    });

    // create https request to access token
    var accessTokenPostOptions = {
        hostname: ACCESS_TOKEN_HOST,
        path: ACCESS_TOKEN_PATH,
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Content-Length': Buffer.byteLength(accessTokenPostData)
        }
    };

    var accessTokenPostReq = https.request(accessTokenPostOptions, function(response) {
        response.setEncoding('utf8');
        var responseData = '';

        response.on('data', function(chunk) {
            responseData += chunk;
        });

        response.on('end', function() {
            var JSONParsedResponse = JSON.parse(responseData);
            var accessToken = JSONParsedResponse.access_token;
            console.log(`access_token successfully obtained for senderAddress <${senderAddress}>`)
            sendEmail(senderAddress, accessToken, region);
        });

        response.on('error', function(errorMsg) {
            console.log(`!!!!!failed to get access token: ${errorMsg}`)
        });
    });

    accessTokenPostReq.write(accessTokenPostData);
    accessTokenPostReq.end();
}

// send email to senderAddress using input accessToken
function sendEmail(senderAddress, accessToken, region) {
    var email_uuid = uuid.v4();
    var recipient = `monitor.recipient@${US_WEST_2_RECIPIENT_DOMAIN}`;
    var date = new Date().toISOString();

    var emailSubject = `Sophos ${region} MailFlow Outbound RoundTrip Monitoring ${date}`;
    var email = JSON.stringify({
        "message": {
            "subject": emailSubject,
            "body": {
                "contentType": "Text",
                "content": ""
            },
            "toRecipients": [
                {
                    "emailAddress": {
                        "address": recipient
                    }
                }
            ]
        },
        "saveToSentItems": "true"
    });

    var sendEmailPostOptions = {
        hostname: SEND_EMAIL_HOST,
        path: `/v1.0/users/${senderAddress}/sendMail`,
        method: 'POST',
        headers: {
            'Content-Length': Buffer.byteLength(email),
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
        }
    };

    var sendEmailPostReq = https.request(sendEmailPostOptions, function(response) {
        if (response.statusCode === 202) {
            console.log(`email with subject <${emailSubject}> successfully sent`);
        }

        response.on('error', function(errorMessage) {
            console.log(`!!!!!failed to send email with subject <${emailSubject}>: ${errorMessage}`);
        });
    });
    sendEmailPostReq.write(email);
    sendEmailPostReq.end();
}