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
#### Setup AWS profile
##### Command :
```aws configure --profile docker-amzn```
##### Output :
```
AWS Access Key ID [None]: AKIAIMKUB4FSRCN5MECQ
AWS Secret Access Key [None]: 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
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
