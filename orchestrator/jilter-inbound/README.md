# in order to run docker-compose, you will need a directory structure created
# and a global.CONFIG file under ~/.policy-storage/config/inbound-relay-control/multi-policy
# the final script should create this folder structure during sandbox install

# to  build container
docker-compose build 

# to start the container
docker-compose up -d

# login to the running container to check if java is running
docker exec -it jilter-inbound bash

# ps aux | grep java