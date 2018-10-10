This is a Tomcat server image which is similar to what is used by Nova for the app-server.

# instructions to build and push xgemail/sophos_cloud_tomcat to aws ECR

#step 1
login:
$(aws ecr get-login --no-include-email --region us-east-2)

#step 2 
build image: 
docker build -t xgemail/sophos_cloud_tomcat .

#step 3 
tag the image: 
docker tag xgemail/sophos_cloud_tomcat:latest 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/sophos_cloud_tomcat:latest

#step 4 
push the image 
docker push 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/sophos_cloud_tomcat:latest