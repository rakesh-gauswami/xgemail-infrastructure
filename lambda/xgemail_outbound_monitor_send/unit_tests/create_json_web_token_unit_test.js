/*
 * Copyright 2019 Sophos Limited. All rights reserved.
 *
 * 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of Sophos Limited and Sophos Group. All other product
 * and company names mentioned are trademarks or registered trademarks of their respective owners.
 */

var tokenModule = require('../create_json_web_token');
var jwt = require('jsonwebtoken');
var assert = require('assert');

const TEST_THUMBPRINT = '8D:53:F6:91:B0:EE:03:29:2C:5F:69:D7:FA:BB:CA:A4:2E:E0:8C:C0';
const TEST_PRIVATE_KEY_LOCATION = process.env.XGEMAIL_US_WEST_2_PRIVATE_KEY_LOCATION;
const TEST_PUBLIC_KEY_LOCATION = process.env.XGEMAIL_US_WEST_2_PUBLIC_KEY_LOCATION;
const TEST_PUBLIC_KEY_THUMBPRINT_LOCATION = process.env.XGEMAIL_US_WEST_2_PUBLIC_KEY_THUMBPRINT_LOCATION;
const TEST_CLIENT_ID = '12345';
const TEST_TENANT_ID = '6789';
const TEST_SENDER_ADDRESS = '[unit_test]testCreateToken';
const TEST_REGION = '[unit_test]USWEST2'

var testCreateX5TValue = function() {
    var actualX5TValue = 'jVP2kbDuAyksX2nX-rvKpC7gjMA';
    var expectedX5TValue = tokenModule.createX5TValue(TEST_THUMBPRINT);
    assert.equal(actualX5TValue, expectedX5TValue, "[unit_test]testCreateX5T unit test failed");
    console.log('[unit_test]testCreateX5TValue unit test passed');
}

var testCreateToken = function() {
    var actualAudience = `https://login.microsoftonline.com/${TEST_TENANT_ID}/oauth2/token`;

    var tokenPromise = tokenModule.createToken(TEST_CLIENT_ID, TEST_TENANT_ID, TEST_REGION, TEST_SENDER_ADDRESS,
        TEST_PRIVATE_KEY_LOCATION, TEST_PUBLIC_KEY_THUMBPRINT_LOCATION);

    var publicKeyPromise = retrievePublicKey(TEST_PUBLIC_KEY_LOCATION);

    Promise.all([tokenPromise, publicKeyPromise])
        .then(function(results) {
            var token = results[0]['token'];
            var publicKey = results[1];
            console.log('[unit_test]successfully obtained public key and token for testCreateToken unit test');

            //verify token signature with public key and ensure token's elements are correct
            jwt.verify(token, publicKey, {
                algorithms: ['RS256'],
                audience: actualAudience,
                issuer: TEST_CLIENT_ID,
                subject: TEST_CLIENT_ID
            }, function(err, decoded) {
                if (err)
                {
                    console.log(`!!!!![unit_test]testCreateToken unit test failed : ${err}`);
                }
                else if (decoded)
                {
                    console.log('[unit_test] testCreateToken unit test passed');
                }
            });
        }, function(errorMsg) {
            console.log(`!!!!![unit_test]failed to retrieve public key and token for unit testing: ${errorMsg}`);
        });
}

// retrieve public key
function retrievePublicKey(publicKeyLocation) {
    return new Promise(function(resolve, reject) {
        var publicKeyRequest = tokenModule.getKeyRequest(publicKeyLocation);

        publicKeyRequest.
        on('success', function(response) {
            resolve(response.data.Body);
        }).
        on('error', function(errorMsg) {
            reject(errorMsg);
        }).
        send()
    })
}

module.exports.testCreateX5TValue = testCreateX5TValue;
module.exports.testCreateToken = testCreateToken;