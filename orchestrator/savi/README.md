#Instruction to build / test Savi container

# run docker-compose up -d 

# on the host computer, run following command:
telnet localhost 4010

# you should expect response similar to following:
Trying ::1...
Connected to localhost.
Escape character is '^]'.
OK SSSP/1.0

#enter following request to test the resposne
SSSP/1.0  should get a response: ACC 5B992B5C/1

QUERY ENGINE should get a list of response


# Check following wiki link for more information
https://wiki.sophos.net/display/NSG/SAVI+Integration