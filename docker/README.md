Docker Images for Email Sandbox
============================

Requirements
------------
#### AWS CLI
```brew install awscli```
#### AWS Credentials
`./xgemail-ecr-readonly.csv` - AWS credentials file.

Setup
----------
Download AWS credentials from [wiki](https://wiki.sophos.net/download/attachments/291609046/xgemail-ecr-readonly.csv?api=v2) 
#### Setup AWS profile
##### Command :
```aws configure --profile docker-amzn```
##### Output :
```
AWS Access Key ID [None]: xxxxx   -- Refer downloaded credential file
AWS Secret Access Key [None]: xxxx -- Refer downloaded credential file
Default region name [None]: us-east-2
Default output format [None]: json
```

Usage
-----
1) Login into AWS.
##### Command : 
```$(aws ecr get-login --no-include-email --region us-east-2 --profile docker-amzn)```
##### Output :
```
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
Login Succeeded
```

2) Retrieve docker images
##### Command :
```
docker pull 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/xgemail-base
docker pull 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/postfix
```
