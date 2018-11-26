Docker Images for Email Sandbox
============================

Requirements
------------
#### AWS CLI
```brew install awscli```

Configure AWS INF credentials
----------
1) Install the following chrome plugin https://chrome.google.com/webstore/detail/saml-to-aws-sts-keys-conv/ekniobabpcnfjgfbphhcolcinmnbehde?hl=en
2) When your login through myapps.microsoft.com as soon as you get to an aws console it will download a credentials file 
3) Copy the credentials file to your aws account. Please note that these credentials will be valid upto 12 hrs.
```cp  ~/Downloads/credentials  ~/.aws/credentials```


Usage
-----
1) Login into AWS.
##### Command : 
```$(aws ecr get-login --no-include-email --region us-east-2)```
##### Output :
```
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
Login Succeeded
```
