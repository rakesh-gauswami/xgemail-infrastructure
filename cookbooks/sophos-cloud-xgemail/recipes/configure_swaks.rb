#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure_swaks
#
# Copyright 2022, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

ACCOUNT_NAME = node['sophos_cloud']['account_name']
NODE_TYPE    = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

SOPHOS_SWAKS_DIR = '/opt/swaks'
SOPHOS_SWAKS_SUBJECTLINE_FILE = '/opt/swaks/subjectline.txt'

directory SOPHOS_SWAKS_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

bash 'download_swaks' do
  user 'root'
  cwd '/opt/swaks'
  code <<-EOH
    echo "$(curl -O https://jetmore.org/john/code/swaks/files/swaks-20201014.0/swaks)"
    /bin/chmod +x /opt/swaks/swaks
  EOH
end

file SOPHOS_SWAKS_SUBJECTLINE_FILE do
  content '"Subject: welcome: to the warm up session"\n
"Subject: Hello! This is the subject header"\n
"Subject: Question about the warmingup"\n
"Subject: Mutual connection recommended to get warmed up"\n
"Subject: Did you get what you were looking for?"\n
"Subject: Hoping to help for warmupup"\n
"Subject: A benefit of reputation"\n
"Subject: tips for the action"\n
"Subject: Idea for getting reputation"\n
"Subject: 10x connections in 10 minutes"\n
"Subject: I found you through the Academic seminar"\n
"Subject: We have reputation service in common ..."\n
"Subject: So nice to meet you, on workshop!"\n
"Subject: Feeling depressed? Let me help"\n
"Subject: Hoping you can help."\n
"Subject: This is a warmup email"\n
"Subject: Your yearly target"\n
"Subject: Situation at the process"\n
"Subject: Who is in charge of reputation"\n
"Subject: Have you tried reaching out our CustomerSupport team?"\n
"Subject: So, you speak sign language?"\n
"Subject: Will cut to the chase"\n
"Subject: Might be off-base here, but ..."\n
"Subject: If you are struggling with reputation, you are not alone"\n
"Subject: Can I make your life 20% easier?"\n
"Subject: warmupuser, saw you are focused on reputation"\n
"Subject: Will I see you at conferance!"\n
"Subject: Can I help?"\n
"Subject: Tired of the administrator who never give up?"\n
"Subject: Warmupuser, suggested I reach out"\n
"Subject: Contacting you at admin suggestion"\n
"Subject: Administrator loves us and thought you might, too"\n
"Subject: Fellow engineers grad here!"\n
"Subject: Our next steps"\n
"Subject: Best options to get started"\n
"Subject: You are not alone."\n
"Subject: 10 mins — on next Friday?"\n
"Subject: A 3-step plan for your busy week"\n
"Subject: I thought you might like these blogs"\n
"Subject: Here is that info I promised you"\n
"Subject: I would love your feedback on that meeting"\n
"Subject: I had this idea since we last spoke"\n
"Subject: I thought about what you said"\n
"Subject: Do not revel this to all"\n
"Subject: What would it take?"\n
"Subject: Here is what I will do"\n
"Subject: Talk on Monday at 11:30?"\n
"Subject: Late Winter Security Stir Crazy "\n
"Subject: This Veterans Day Pick Late Fall Lures at Special Discount"\n
"Subject: A Secure Message everyone Need to Read"\n
"Subject: Did you see this! - hope I catch you this time"\n
"Subject: Thank God that is over"\n
"Subject: Falling short of reaching your business goals?"\n
"Subject: How does Admin On-Call work?"\n
"Subject: Welcome to Admin On-Call"\n
"Subject: We are Admin On-Call. Lets stay connected."\n
"Subject: You are part of the Admin On-Call family now"\n
"Subject: You are an Admin On-Call subscriber. Now what?"\n
"Subject: Get started with Admin On-Call"\n
"Subject: You are in! Welcome to Admin On-Call."\n
"Subject: Hurray! You joined the security On-Call team."\n
"Subject: Learn more about Admin On-Call."\n
"Subject: Get 10% off your next security service"\n
"Subject: Check out our August service specials"\n
"Subject: Introducing our new Customer Program"\n
"Subject: Book a new service and earn reward points"\n
"Subject: Get a complimentary gift when you buy a new service"\n
"Subject: Flash sale alert on all services!"\n
"Subject: Application maintenance plans - 30% off"\n
"Subject: Select maintenance services - 25% off!"\n
"Subject: Get a maintenance plan with your Application installation"\n
"Subject: Black Friday Sale on all services"\n
"Subject: Feel merry with 10% off your next service"\n
"Subject: Save 30% on select services before the New Year"\n
"Subject: We are thankful for you. Enjoy 15% off your next service."\n
"Subject: Jingle bells! Save 25% on licence upgrade."\n
"Subject: 5 holiday gifts with the license upgrade"\n
"Subject: Happy holidays! Unwrap your savings on your new Application."\n
"Subject: Get cozy this winter with a new warmup service"\n
"Subject: Summer is near. Schedule your Application maintenance service."\n
"Subject: You will fall in love with February service specials."\n
"Subject: Our winter service savings plan is here"\n
"Subject: We are glad you said yes to securitys On-Call."\n
"Subject: Next steps after your service appointment"\n
"Subject: New details about your maintenance agreement"\n
"Subject: Nice speaking with you about installation services"\n
"Subject: Lets take another look at your service agreement"\n
"Subject: Application service appointment at 12:00 p.m."\n
"Subject: Great talking with you today"\n
"Subject: Still in the market for new maintenance services?"\n
"Subject: Ready to install your new endpoint security app?"\n
"Subject: More about our security services"\n
"Subject: One thing I forgot to mention..."\n
"Subject: Your Application license is expiring soon"'
  mode '0644'
  owner 'root'
  group 'root'
end
