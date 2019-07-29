/*
 * Copyright 2019 Sophos Limited. All rights reserved.
 *
 * 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of Sophos Limited and Sophos Group. All other product
 * and company names mentioned are trademarks or registered trademarks of their respective owners.
 */

var aws = require('aws-sdk');
var jwt = require('jsonwebtoken');
var uuid = require('uuid');

// number of seconds from now after which token expires
const JWT_LIFETIME = 180;

const KEY_BUCKET = process.env.XGEMAIL_ROUNDTRIP_KEYS_BUCKET_NAME;

// This methods transforms the X.509 certificate SHA-1 thumbprint(x5t) into a form that can be used to create the JSON Web Token
// x5t values are generally encoded in the form B4:90:83:23:12:...
// This method removes the colons, lowercases the result and converts the hex string to base64
var createX5TValue = function(thumbprint) {
    var hexString = thumbprint.toLowerCase().replace(/:/g, '').replace(/ /g, '').trim();
    var base64 = (new Buffer(hexString, 'hex')).toString('base64');
    return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
};

// request key from s3
var getKeyRequest = function(keyLocation) {
    var s3 = new aws.S3({apiVersion: '2006-03-01'});
    var keyRequestParams = {'Bucket' : KEY_BUCKET, 'Key': keyLocation};
    var keyRequest = s3.getObject(keyRequestParams);
    return keyRequest;
};

// generate JSON Web token
var createToken = function(clientID, tenantID, region, senderAddress, privateKeyLocation, publicKeyThumbprintLocation) {
    return new Promise(function(resolve, reject) {
        //obtain public key thumbprint and private key promises
        var publicKeyThumbprintPromise = retrievePublicKeyThumbprint(publicKeyThumbprintLocation);
        var privateKeyPromise = retrievePrivateKey(privateKeyLocation);

        Promise.all([publicKeyThumbprintPromise, privateKeyPromise])
            .then(function(results) {
                console.log(`successfully obtained public key thumbprint and private key for <${senderAddress}>`);
                var publicKeyThumbprint = results[0];
                var privateKey          = results[1];

                var token = createAndSignJWT(clientID, tenantID, publicKeyThumbprint, privateKey);
                var returnObject = {'token': token, 'clientID': clientID, 'senderAddress': senderAddress, 'region': region}
                resolve(returnObject);
            }, function(errorMsgs) {
                console.log(`!!!!!failed to obtain public key thumbprint and private key for ${senderAddress}: ${errorMsgs}`);
                var returnObject = {'errorMsgs': errorMsgs, 'senderAddress': senderAddress};
                reject(returnObject);
            });
    })
};

// retrieve public key thumbprint
function retrievePublicKeyThumbprint(publicKeyThumbprintLocation) {
    return new Promise(function(resolve, reject) {
        var publicKeyThumbprintRequest = getKeyRequest(publicKeyThumbprintLocation);

        publicKeyThumbprintRequest.
        on('success', function(response) {
            resolve(response.data.Body.toString('UTF-8'));
        }).
        on('error', function(errorMsg) {
            reject(errorMsg);
        }).
        send()
    })
}

//retrieve private key
function retrievePrivateKey(privateKeyLocation) {
    return new Promise(function(resolve, reject) {
        var privateKeyRequest = getKeyRequest(privateKeyLocation);

        privateKeyRequest.
        on('success', function(response) {
            resolve(response.data.Body);
        }).
        on('error', function(errorMsg) {
            reject(errorMsg);
        }).
        send()
    })
}

//create jwt and sign it
function createAndSignJWT(clientID, tenantID, publicKeyThumbprint, privateKey) {
    //remove milliseconds because jwt exp and nbf is expected to be in seconds
    var currentTime = Math.floor(Date.now()/1000);

    var jwtHeader = {
        "alg": "RS256",
        "typ": "JWT",
        "x5t": createX5TValue(publicKeyThumbprint)
    };

    var jwtPayload = {
        "aud": `https://login.microsoftonline.com/${tenantID}/oauth2/token`,
        "iss": clientID,
        "sub": clientID,
        "nbf": currentTime,
        "exp": currentTime + JWT_LIFETIME,
        "jti": uuid.v4()
    };

    var token = jwt.sign(jwtPayload, privateKey, {algorithm: 'RS256', header: jwtHeader});
    return token;
}


module.exports.createToken = createToken;
module.exports.createX5TValue = createX5TValue;
module.exports.getKeyRequest = getKeyRequest;
