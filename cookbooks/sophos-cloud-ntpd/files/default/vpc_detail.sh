#!/bin/bash

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# Call AWS Ec2-metadata URL to get VPC CIDR block details
# http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html

get_mac=$(wget -q -O - http://169.254.169.254/latest/meta-data/network/interfaces/macs/)

get_vpc_cidr=$(wget -q -O - http://169.254.169.254/latest/meta-data/network/interfaces/macs/"$get_mac"vpc-ipv4-cidr-block/)

vpc_network=$(echo $get_vpc_cidr | cut -f1 -d/)
vpc_mask=$(echo $get_vpc_cidr | rev | cut -f1 -d/ | rev)

if [ $vpc_mask == 16 ]
then
    	mask_value="255.255.0.0"
elif [ $vpc_mask == 24 ]
then
    	mask_value="255.255.255.0"
else
    	mask_value="255.255.0.0"
fi

echo $vpc_network "mask" $mask_value > /tmp/result.log

chmod 740 /tmp/result.log

