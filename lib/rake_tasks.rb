require 'foodcritic'
require 'rspec/core/rake_task'

def chef_repo?
  File.exists?('cookbooks')
end

if chef_repo?
  task :spec do
    Dir.glob("cookbooks/*").each do |f|
      next unless File.directory?(f)
      next unless File.exists?(File.join(f, 'spec', 'spec_helper.rb'))
      Dir.chdir(f) do
        sh 'bundle exec rspec'
      end
    end
  end
else
  RSpec::Core::RakeTask.new(:spec)
end

desc "Run foodcritic"
task :foodcritic do
  args = {}
  if chef_repo?
    # we're in the chef-repo
    args[:cookbook_paths] = ['cookbooks']
    args[:include_rules] = Dir.glob('lib/foodcritic/**/rules.rb')
  else
    # we're in a subcookbook
    args[:cookbook_paths] = ['.']
    args[:include_rules] = Dir.glob('../../lib/foodcritic/**/rules.rb')
  end
  print "Running foodcritic ..."

  result = FoodCritic::Linter.new.check args
  if result.failed? # or result.warnings.size > 0
    puts "FAILED"
    puts result
    fail
  else
    puts "OK"
    puts result
  end
end

desc "Run test-kitchen"
task :test_kitchen do
  if chef_repo?
    Dir.glob("cookbooks/*").each do |f|
      next unless File.directory?(f)
      next unless File.exists?(File.join(f, '.kitchen.yml'))
      Dir.chdir(f) do
        sh 'bundle exec kitchen test'
      end
    end

  elsif File.exists?('.kitchen.yml')
    # subcookbook that supports test-kitchen
    sh 'bundle exec kitchen test'
  end
end

desc "Runs knife cookbook test against all cookbooks."
task :knife_test do
  # Load constants from rake config file.
  require File.join(File.dirname(__FILE__), '..', 'config', 'rake')

  if chef_repo?
    sh "knife cookbook test -a"
  end
end

# not adding test_kitchen yet since those tests take a looong time.
task :default => ['foodcritic', 'spec']
