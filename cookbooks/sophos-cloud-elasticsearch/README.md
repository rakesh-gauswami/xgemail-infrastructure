sophos-cloud-elasticsearch cookbook
===========================================
Manage Elasticsearch nodes

Reference
---------
There are a number of online tutorial describing how to write chef recipes.
Here is a good one:

    http://reiddraper.com/first-chef-recipe/

You can also glean a lot by looking at the sibling cookbooks in this directory.

For more details about individual resources within a chef recipe,
look at the online documentation here:

    http://docs.chef.io/resources.html

Guidelines and Reminders
------------------------

You can run 'make' from the top of the cloud-infrastructure repository to
check the syntax or each .rb and .json file, including those in this cookbook.

Make sure errors are detected as early as possible.  For example, in bash
resources, be sure to use set -e to make commands that return a non-zero
exit status cause a failure.
