#sophos-rules
================

These are the foodcritic rules created for testing our own cookbooks. Some are modifications of existing custom rules found on Github while others were written for our particular use cases. These will continue to evolve as we create more cookbooks.

# Usage

Use the following to test your cookbooks using foodcritic:

````
foodcritic -t sophos -I <rules.rb> cookbooks
````

Replace <rules.rb> with the location of the rules.rb file from this repository.

This will run all rules with the "sophos" tag. If you want to check code quality with all foodcritic rules and Sophos rules, use:

````
foodcritic -I <rules.rb> cookbooks
````

You can also run the custom rules against the test cookbooks to confirm that they work. All of the SPHS0XX_fail.rb recipes should be detected by the custom rules. At the root of the sophos-rules folder execute:

````
foodcritic -I rules.rb test-cookbooks
````

# Rules

## SPHS001 - Remove debugging statements
### Modified from TC002 (https://github.com/dlad/foodcritic-rules)

It's good practice to not leave your debugging statements in your cookbooks before checking them into source. This will comb your cookbooks for any puts or print statements.

For example, this block would trip this rule:

````
puts "Text in text in temp"
print "textception"
cookbook_file "test.txt" do
  path "/tmp/text.txt"
  source "text.txt"
  mode 0777
  owner "root"
  group "root"
end
````

## SPHS002 - Use the AWS CLI over s3cmd for managing S3 buckets

This rule detects when s3cmd is being used within a bash or execute resource. We're currently utilizing the AWS CLI for all of our calls to various AWS resources and will continue to use the official tools provided. aws s3 should always be used to access S3 buckets.

For example, these blocks would trip this rule:

````
execute "failing_command" do
  command "s3cmd get s3://BUCKET/OBJECT LOCAL_FILE"
end
````
````
bash "failing_command" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  s3cmd get s3://BUCKET/OBJECT LOCAL_FILE
  EOH
end
````

## SPHS003 - Recipes must correspond to OpsWorks lifecycle events

This rule checks whether or not recipe names coincide with AWS OpsWorks lifecycle events. Any recipe name that does not align with one of the five event types will trip this rule.

Lifecycle events are defined at the top of rules.rb:

````
@lifecycleevents = ["setup.rb", "configure.rb", "deploy.rb", "undeploy.rb", "shutdown.rb"]
````

The five stages of the OpsWorks lifecycle are:
1. setup
2. configure
3. deploy
4. undeploy
5. shutdown

## SPHS004 - Package resource missing specific version number
### Modified from ETSY007 (https://github.com/etsy/foodcritic-rules)

This rule detects if a package is being installed with a specific version number. Divergence is less likely to occur if we lock down package versions to specific releases.

For example, this block would trip this rule:

````
package "git" do
  action :install
end
````

## SPHS005 - Package resource with :upgrade action
### Modified from ETSY001

This rule identifies when the :upgrade action is being used in place of the :install action.

For example, this block would trip this rule:
````
package "git" do
  version "1.0.0"
  action :upgrade
end
````