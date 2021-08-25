#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_iptables_nat_rules
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#
# Create Post Routing NAT rules in IPTABLES to load balance outbound traffic from each of the attached EIPs

MAC = node['macaddress'].downcase
IP_LIST = node['ec2']['network_interfaces_macs'][MAC]['local_ipv4s'].split("\n")
IP_COUNT = IP_LIST.length()

if IP_COUNT > 1
  NAT_RULE_NUM = 1
  IP_LIST.each do |ip|
    NAT_RULE_PROB = 1 / (IP_COUNT - NAT_RULE_NUM + 1).to_f
    bash "setup IPTABLES NAT rules" do
      user "root"
      code "iptables -t nat -A POSTROUTING -o eth0 -p tcp -m statistic --mode random --probability #{NAT_RULE_PROB} -j SNAT --to-source #{ip}"
    end
    NAT_RULE_NUM += 1
  end
end