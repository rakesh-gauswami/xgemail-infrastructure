#instructions to build and push xgemail/jilter-base image to aws ECR
# step 1 - login: 
$(aws ecr get-login --no-include-email --region us-east-2)

#step 2 - build image:
docker build -t xgemail/jilter-base .

#step 3 - tag the image:
docker tag xgemail/jilter-base:latest 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/jilter-base:latest

#step 4 - push the image
docker push 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/jilter-base:latest