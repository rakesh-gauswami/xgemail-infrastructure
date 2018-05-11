# Foodcritic rules
@lifecycleevents = ["setup.rb", "configure.rb", "deploy.rb", "undeploy.rb", "shutdown.rb"]

# Modified from TC002 (https://github.com/dlad/foodcritic-rules)
rule "SPHS001", "Remove debugging statements" do
  tags %w{testing sophos}
  recipe do |ast|
    ast.xpath('//command[ident/@value="puts"]|//command[ident/@value="print"]')
  end
end

rule "SPHS002", "Use the AWS CLI over s3cmd for managing S3 buckets" do
  tags %w{correctness testing sophos}
  recipe do |ast|
    find_resources(ast, :type => "execute").find_all do |cmd|
      command = resource_attribute(cmd, 'command').to_s
      command.include?('s3cmd')
    end
    find_resources(ast, :type => "bash").find_all do |cmd|
      code = resource_attribute(cmd, 'code').to_s
      code.include?('s3cmd')
    end
  end
end

rule "SPHS003", "Recipes must correspond to OpsWorks lifecycle events" do
  tags %w{correctness opsworks recipe sophos}
  recipe do |ast, filename|
    recipe_path = filename.to_s
    recipe_name = recipe_path.split("/").last
    unless !recipe_path.include?("recipes")
      unless @lifecycleevents.include?(recipe_name)
        [file_match(filename)]
      end
    end
  end
end

# Modified from ETSY007 (https://github.com/etsy/foodcritic-rules)
rule "SPHS004", "Package resource missing specific version number" do
  tags %w{recipe resource style sophos}
  recipe do |ast|
    find_resources(ast, :type => 'package').find_all do |package|
      version = resource_attribute(package, 'version')
      version.nil?
    end
  end
end

# Modified from ETSY001
rule "SPHS005", "Package resource with :upgrade action" do
  tags %w{correctness sophos}
  recipe do |ast|
    find_resources(ast, :type => 'package').find_all do |package|
      action = resource_attribute(package, 'action').to_s
      action.include?('upgrade')
    end
  end
end
