#
# Cookbook Name:: sophos-cloud-tomcat
# Recipe:: configure -- this runs during AMI deployment
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Configure Tomcat options

java_home_path = "`(readlink -f /usr/lib/jvm/default-java | sed \"s:bin/java::\")`"
postfix_path ="/etc/postfix"
mailname_path ="/etc"
mongos_net_port = node["mongo"]["mongos_net_port"]
sasl_file_path = "#{postfix_path}/sasl_passwd"
sophos_tmp_path = node['sophos_cloud']['tmp']
sophos_script_path = node['sophos_cloud']['script_path']
is_station = node['sophos_cloud']['cluster'] != 'hub' && node['sophos_cloud']['cluster'] != 'dep'
is_java_app = node['sophos_cloud']['is_java_app'] == "yes"
lc_account_name = node['sophos_cloud']['environment'].downcase
email_relay_host_name = lc_account_name == 'dev3' ? '54.194.35.229' : 'asp-submit.reflexion.net'
email_password_file_name = 'sasl_passwd'
email_relay_user = "#{lc_account_name}_auth@cloud.sophos.com"


if is_java_app
  # Including here to keep run list shorter
  directory '/var/log/sophos-tomcat' do
    owner 'tomcat'
  end

  include_recipe 'sophos-cloud-fluentd::tomcat-json'
end

if node['sophos_cloud']['direct_deploy'] == 'false'

  # Copy the WAR to the webapps directory
  bash "copy_war_to_webapps" do
    user "root"
    cwd "/tmp"
    code <<-EOH
        cp /tmp/#{node['sophos_cloud']['cluster']}.war #{node['tomcat']['webapp_dir']}/#{node['sophos_cloud']['war_name']}.war
    EOH
    only_if { is_java_app }
  end

  # Override Variables
  override_path = "apps/#{node['sophos_cloud']['region']}/#{node['sophos_cloud']['vpc_name']}"
  override_key = "#{node['sophos_cloud']['cluster']}.war"

  # Check if there is an override WAR in S3
  bash "get_override_war_from_s3" do
    user "root"
    cwd node['tomcat']['webapp_dir']
    code <<-EOH
        aws configure set default.s3.signature_version s3v4
        aws s3 --region us-west-2 cp \
            s3://#{node['sophos_cloud']['configs']}/#{override_path}/#{override_key} \
            #{node['tomcat']['webapp_dir']}/#{node['sophos_cloud']['war_name']}.war || true
    EOH
    only_if { is_java_app }
  end
else
  # Get the war directly from s3

  # NOTE: current assumption is {SERVICE NAME}-services.war  This works for most services...but a few it doesn't
  #       This is fine for now since it is only being used for mcs...but it needs to be updated for other services""
  # TODO: Refactor for bi-exporter and mobile to work
  bash "get_war_from_s3" do
    user "root"
    cwd node['tomcat']['webapp_dir']
    code <<-EOH
        aws configure set default.s3.signature_version s3v4
        aws s3 --region us-east-1 cp \
            s3://sophos-central-soa-artifacts/#{node['sophos_cloud']['branch']}/#{node['sophos_cloud']['build_number']}/#{node['sophos_cloud']['cluster']}-services.war \
            #{node['tomcat']['webapp_dir']}/#{node['sophos_cloud']['war_name']}.war
    EOH
    only_if { is_java_app }
  end
end



# Update permissions of override WAR
file "#{node['tomcat']['webapp_dir']}/#{node['sophos_cloud']['war_name']}.war" do
  owner "root"
  group "root"
  mode "0644"
  only_if { is_java_app }
end

# The presence of the directory "/data/var/conf" is established in
# 'deploy_certs.rb', which all the templates call before calling this
# recipe. That is: *today*. Fragile.

cookbook_file "/data/var/conf/context.xml" do
  source "context.xml"
  mode "0644"
  owner "tomcat"
  group "tomcat"
end

# Create web.xml symlink
link "/data/var/conf/web.xml" do
  to "/usr/share/tomcat/conf/web.xml"
  link_type :symbolic
  mode "0644"
  owner "tomcat"
  group "tomcat"
  only_if { is_java_app }
end

# Create work (cache) directory
directory "/data/var/work" do
  mode "0755"
  owner "tomcat"
  group "tomcat"
end

service "postfix" do
  action [:disable, :stop]
  only_if { node['email']['install'] == "yes" }
end

bash "download_sasl_password" do
  user "root"
  cwd "#{sophos_script_path}"
  code <<-EOH
    set -e

    aws configure set default.s3.signature_version s3v4

    # Make sure that downloaded file is only root readable
    umask 0077

    #{node['sophos_cloud']['script_path']}/download-object \
                      #{node['sophos_cloud']['context']} \
                      #{node['sophos_cloud']['connections']} \
                      #{email_password_file_name} \
                      "#{sophos_tmp_path}/#{email_password_file_name}" || true
  EOH
  only_if { node['email']['install'] == "yes" }
end

log "Password file downloaded to: '#{sophos_tmp_path}/#{email_password_file_name}'" do
  level :info
  only_if { node['email']['install'] == "yes" }
end

template "postfix-main-cf" do
  path "#{postfix_path}/main.cf"
  source "postfix.main.cf.erb"
  variables({
          :host_name => node['ec2']['local_hostname'],
          :relay_host_name => email_relay_host_name,
          :mail_version => node['email']['mail_version'],
          :cert_path_filename => "#{node['sophos_cloud']['local_cert_path']}/#{node['email']['key_filename']}.crt",
          :key_path_filename => "#{node['sophos_cloud']['local_key_path']}/#{node['email']['key_filename']}.key"
          })
  mode "0644"
  owner "root"
  group "root"
  only_if { node['email']['install'] == "yes" }
end

template "postfix-master-cf" do
  path "#{postfix_path}/master.cf"
  source "postfix.master.cf.erb"
  mode "0644"
  owner "root"
  group "root"
  only_if { node['email']['install'] == "yes" }
end

bash "create-postfix-sasl-passwd" do
  user "root"
  cwd "#{sophos_tmp_path}"
  code <<-EOH
    rm -f '#{sasl_file_path}'

    sasl_password_found=$( cat '#{sophos_tmp_path}/#{email_password_file_name}' )
    # Remove leading whitespace
    sasl_password_found="${sasl_password_found#"${sasl_password_found%%[![:space:]]*}"}"
    # Remove trailing whitespace
    sasl_password_found="${sasl_password_found%"${sasl_password_found##*[![:space:]]}"}"

    # Make sure that created sasl_password is only root readable
    umask 0077

    sasl_file='#{postfix_path}/sasl_passwd'

    echo '# destination credentials' > "${sasl_file}"
    echo "[#{email_relay_host_name}]:587 #{email_relay_user}:${sasl_password_found}" >> "${sasl_file}"
  EOH
  only_if { node['email']['install'] == "yes" }
end

bash "rehash_sasl_passwd" do
  user "root"
  cwd "#{sophos_tmp_path}"
  code <<-EOH
    # Make sure that created hashed file is only root readable
    umask 0077

    postmap #{postfix_path}/sasl_passwd
  EOH
  only_if { node['email']['install'] == "yes" }
end

file sasl_file_path do
  action :delete
end

template "postfix-mailname" do
  path "#{mailname_path}/mailname"
  source "postfix.mailname.erb"
  variables({
          :host_name => node['email']['host_name']
           })
  mode "0644"
  owner "root"
  group "root"
  only_if { node['email']['install'] == "yes" }
end

# Certain configurations of postfix (including the default) require some additional setup be run. (http://www.postfix.org/INSTALL.html#hamlet)
cookbook_file "postfix_fix_script" do
  path "#{postfix_path}/LINUX2"
  source "LINUX2"
  mode "0744"
  owner "root"
  group "root"
  only_if { node['email']['install'] == "yes" }
end

# This is used to set email_domain for different environments
mail_domains = {
  "dev" => "p0.d.hmr.sophos.com",
  "dev3" => "p0.d3.hmr.sophos.com",
  "dev4" => "p0.d4.hmr.sophos.com",
  "inf" => "p0.i.hmr.sophos.com",
  "qa" => "p0.q.hmr.sophos.com",
  "prod" => "central.sophos.com"
 }

mail_domain = mail_domains[lc_account_name]

raise "Unsupported account name [#{lc_account_name}] when resolving mail domain" if mail_domain.nil?

bash "setup_vmailbox" do
  user "root"
  cwd postfix_path
  code <<-EOH
    touch vmailbox
    echo "do-not-reply@#{mail_domain} 1"  > vmailbox
    postmap vmailbox

    touch local
    postmap local

    ./LINUX2
  EOH
  only_if { node['email']['install'] == "yes" }
end


# This is used to override a bunch of package names as they were created and needed their names changed.
# Defaultly it will download the package called {service_name}.zip and place it in the /usr/local/etc/sophos dir
# The overrides will change it so it downloads a {source}.zip and copies it to /user/local/etc/sophos/{target}.zip
AKM_OVERRIDES = {
    # Dep instances use the same package as Hub instances since they are the same code.
    # This ensures it downloads the hub package and properly keeps its name of hub.zip
    "dep" =>
        {
            "source" => "hub",
            "target" => "hub",
        },
    "mail" =>
        {
            "source" => "xgemail",
            "target" => "mail",
        },
    "mob" =>
        {
            "source" => "mobile",
            "target" => "mobile",
        },
    "dp" =>
        {
            "source" => "dprot",
            "target" => "dprot",
        },
}

if AKM_OVERRIDES.key?(node['sophos_cloud']['cluster'])
  akm_source = AKM_OVERRIDES[node['sophos_cloud']['cluster']]["source"]
  akm_target = AKM_OVERRIDES[node['sophos_cloud']['cluster']]["target"]
else
  akm_source = node['sophos_cloud']['cluster']
  akm_target = node['sophos_cloud']['cluster']
end

bash "download_application_and_bootstrap_properties" do
  user "root"
  cwd "/tmp"
  code <<-EOH
        mkdir -p /tmp/sophos

        aws configure set default.s3.signature_version s3v4

        # See /var/sophos/cookbooks/attributes.json for definitions on the system.
        ACCOUNT=#{node['sophos_cloud']['context']}
        BUCKET=#{node['sophos_cloud']['configs']}
        CLUSTER=#{node['sophos_cloud']['cluster']}
        REGION=#{node['sophos_cloud']['client-endpoint']}
        BRANCH=#{node['sophos_cloud']['branch']}
        VPC_NAME=#{node['sophos_cloud']['vpc_name']}

        ## Our ansible configuration framework is going to place files following
        ## a different pattern than the legacy mechanism;

        ## We expect this structure for good objects, with '.txz' being the only supported file type:
        ##   common/ansible/__branch__/feature/CPLAT-10580-ansible-sqs-0708-0/__entity__/us-east-1/CloudStation/api.txz
        ##   common/ansible/__branch__/feature/CPLAT-10580-ansible-sqs-0708-0/__entity__/us-east-1/CloudStation/csg.txz

        ## To be backwards compatible we try to find the configuration data first in the new location!
        ## If there's no file in the new location, the code will look at the old location.
        ## The hopper put-config script stored the files in: common/

        PROPERTIES_TXZ=common/ansible/__branch__/${BRANCH}/__entity__/${REGION}/${VPC_NAME}/${CLUSTER}.txz
        tmp_txz=/tmp/sophos/${CLUSTER}.txz

        if aws --region us-west-2 s3 cp s3://${BUCKET}/${PROPERTIES_TXZ} ${tmp_txz}; then
            (
                echo "==== Load Ansible Configuration ===="
                set -x
                tar -xJvf ${tmp_txz} -C #{node['tomcat']['sophos_dir']}/
                rm -f ${tmp_txz}
            ) 2>&1 | tee #{node['tomcat']['sophos_dir']}/the-way-we-got-this
        else
            (
                echo "==== Load Hopper Configuraton ===="
                set -x
                PROPERTIES_TGZ=${ACCOUNT}-${REGION}-config-${CLUSTER}.tar.gz
                aws --region us-west-2 s3 cp s3://${BUCKET}/common/${PROPERTIES_TGZ} /tmp/sophos
                tar -xzvf /tmp/sophos/${PROPERTIES_TGZ} -C #{node['tomcat']['sophos_dir']}/
                rm -f /tmp/sophos/${PROPERTIES_TGZ}
            ) 2>&1 | tee #{node['tomcat']['sophos_dir']}/the-way-we-got-this
        fi

        aws --region us-west-2 s3 cp s3://${BUCKET}/common/${ACCOUNT}-config-akm#{akm_source}.zip /tmp/sophos || true
        mv /tmp/sophos/${ACCOUNT}-config-akm#{akm_source}.zip #{node['tomcat']['sophos_dir']}/#{akm_target}.zip || true

  EOH
end

bash "restore_permissions_bootstrap_properties" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    chown -R tomcat:tomcat #{node['tomcat']['sophos_dir']}/
  EOH
end

bootstrap_report_path = node['tomcat']['sophos_dir'] + "/report/"
bootstrap_report_file = bootstrap_report_path + "bootstrap.properties"
bootstrap_file = node['tomcat']['sophos_dir'] + "/bootstrap.properties"
bootstrap_file_tmp = node['tomcat']['sophos_dir'] + "/bootstrap.properties.tmp"

directory bootstrap_report_path do
  mode "0700"
  owner "tomcat"
  group "tomcat"
  action :create
end

remote_file bootstrap_file_tmp do
  source "file://" + bootstrap_file
  owner 'tomcat'
  group 'tomcat'
  mode 0600
end

ruby_block "remove_credentials_from_reported_bootstrap" do
  block do
    sed = Chef::Util::FileEdit.new(bootstrap_file_tmp)
    sed.search_file_delete_line('[uU][sS][eE][rR][nN][aA][mM][eE]')
    sed.search_file_delete_line('[pP][aA][sS][sS][wW][oO][rR][dD]')
    sed.search_file_delete_line('[kK][eE][yY]')
    sed.search_file_delete_line('[tT][oO][kK][eE][nN]')
    sed.search_file_delete_line('[aA][uU][tT][hH][iI][dD]')
    sed.write_file
  end
end

remote_file bootstrap_report_file do
  source "file://" + bootstrap_file_tmp
  owner 'tomcat'
  group 'tomcat'
  mode 0600
end

file bootstrap_file_tmp do
  action :delete
end

file bootstrap_file_tmp + ".old" do
  action :delete
end

application_report_file = bootstrap_report_path + "application.properties"
application_file = node['tomcat']['sophos_dir'] + "/application.properties"
application_file_tmp = node['tomcat']['sophos_dir'] + "/application.properties.tmp"

remote_file application_file_tmp do
  source "file://" + application_file
  owner 'tomcat'
  group 'tomcat'
  mode 0600
end

ruby_block "remove_credentials_from_reported_application_properties" do
  block do
    sed = Chef::Util::FileEdit.new(application_file_tmp)
    sed.search_file_delete_line('[uU][sS][eE][rR][nN][aA][mM][eE]')
    sed.search_file_delete_line('[pP][aA][sS][sS][wW][oO][rR][dD]')
    sed.search_file_delete_line('[kK][eE][yY]')
    sed.search_file_delete_line('[tT][oO][kK][eE][nN]')
    sed.search_file_delete_line('[aA][uU][tT][hH][iI][dD]')
    sed.write_file
  end
end

remote_file application_report_file do
  source "file://" + application_file_tmp
  owner 'tomcat'
  group 'tomcat'
  mode 0600
end

file application_file_tmp do
  action :delete
end

file application_file_tmp + ".old" do
  action :delete
end

service_report_file = bootstrap_report_path + "service.properties"
service_file = node['tomcat']['sophos_dir'] + "/service.properties"
service_file_tmp = node['tomcat']['sophos_dir'] + "/service.properties.tmp"

remote_file service_file_tmp do
  source "file://" + service_file
  owner 'tomcat'
  group 'tomcat'
  mode 0600
  only_if { is_station && is_java_app }
end

ruby_block "remove_credentials_from_reported_service_properties" do
  block do
    sed = Chef::Util::FileEdit.new(service_file_tmp)
    sed.search_file_delete_line('[uU][sS][eE][rR][nN][aA][mM][eE]')
    sed.search_file_delete_line('[pP][aA][sS][sS][wW][oO][rR][dD]')
    sed.search_file_delete_line('[kK][eE][yY]')
    sed.search_file_delete_line('[tT][oO][kK][eE][nN]')
    sed.search_file_delete_line('[aA][uU][tT][hH][iI][dD]')
    sed.write_file
  end
  only_if { is_station && is_java_app }
end

remote_file service_report_file do
  source "file://" + service_file_tmp
  owner 'tomcat'
  group 'tomcat'
  mode 0600
  only_if { is_station && is_java_app }
end

file service_file_tmp do
  action :delete
  only_if { is_station && is_java_app }
end

file service_file_tmp + ".old" do
  action :delete
  only_if { is_station && is_java_app }
end

# TODO: Run this in the AMI build, not the deployment.
bash "restore_permissions_jre" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    chown -R root:root #{java_home_path}
  EOH
end

bash "delete_temp_files" do
  user "root"
  cwd"/"
  code <<-EOH
    find / -name "._*" -type f -delete
  EOH
end

chef_gem "parseconfig" do
  action :install
end

ruby_block "register_service_using_procon_api" do
  block do
    require "json"
    require "parseconfig"

    # Load properties files into memory.
    app_properties = ParseConfig.new("#{node['tomcat']['sophos_dir']}/application.properties")
    service_properties = ParseConfig.new("#{node['tomcat']['sophos_dir']}/service.properties")

    # Get instance type from application.properties file.
    inst_type = app_properties['application.cluster'].split('_')[-1]

    # Get procon services API URL components from service.properties file.
    host = service_properties['iapi_procon_hostname']


    # Build Java registration call
    url_java = "https://#{host}:8445/iapi/procon/services"

    # Build request from instance-agnostic and instance-specific settings.
    request = {}
    request['id'] = service_properties['service_id']
    request['product']  = 'upe'
    request['product_type'] = service_properties['product_type']
    request['location'] = 'amzn-' + node['sophos_cloud']['client-endpoint']
    request['network_id'] = node['sophos_cloud']['vpc_id']


    # Hub won't be deployed to VPC for a while,
    # and we want to minimize changes to procon code.
    # request['hub_api_url'] = 'https://hub.p0.' + service_properties['root_domain']

    # Iterate over assignments specific to current instance type.
    (service_properties[inst_type] || {}).each do |key, value|
      request[key] = value
    end

    data = JSON.generate(request)

    # The -f option ensures that curl will return a non-zero exit status
    # if the HTTP request does not return an error code signifying success.

    # The -s option disables the progress bar and error messages.
    # The -S option restores error messages disabled by -s.

    # The iapi certificates are self-signed so we need to use the -k
    # (a.k.a. --insecure) option for the curl command to succeed.

    # Use backticks to swallow command output so we don't log the service
    # authentication id and token values in the service record returned
    # by the query.

    # Java registration against dep-services
    `curl --cert /etc/ssl/certs/#{node['cert']['default']}.crt --key /etc/ssl/private/#{node['cert']['default']}.key -f -s -S -k -H Content-Type:application/json -d '#{data}' #{url_java}`

    if not $?.success?
      Chef::Log.warn("#{inst_type} dep-services registration failed: request #{request}")
    else
      Chef::Log.info("#{inst_type} dep-services registration succeeded: request #{request}")
    end

  end
  only_if { is_station && is_java_app }
end

if "#{node['sophos_cloud']['use_elasticache']}" == "true"
  ruby_block "replace_redisPool_addresses_with_ElastiCache_addresses" do
    block do
      sed = Chef::Util::FileEdit.new(bootstrap_file)
      redis_address = "redis"
      redis_address << ".#{node['sophos_cloud']['vpc_name']}".downcase
      redis_address << ".#{node['ec2']['placement_availability_zone'].chop}".downcase
      redis_address << ".#{node['sophos_cloud']['environment']}".downcase
      redis_address << ".hydra.sophos.com:6379"

      sed.search_file_replace_line('.*redisPool.addresses.*',"redisPool.addresses = #{redis_address}")
      sed.search_file_replace_line('.*redisPool.password.*',"redisPool.password=")
      sed.write_file
    end
    only_if { is_java_app }
  end
end

# Replace for SQS Java application usage, required to be VPC ID
ruby_block "replace_application_network_with_vpc_id" do
  block do
    sed = Chef::Util::FileEdit.new(application_file)
    sed.search_file_replace_line('.*application.network.*',"application.network = #{node['sophos_cloud']['vpc_id']}")
    sed.write_file
  end
  only_if { is_java_app }
end

# On PROD ONLY, replace p0.p.hmr.sophos.com with cloud.sophos.com in the hubUrl property.
ruby_block "replace_p0.p.hmr_with_cloud_in_hubUrl_setting" do
  block do
    sed = Chef::Util::FileEdit.new(bootstrap_file)
    sed.search_file_replace_line(
      "deployment.hubUrl *= *https://p0.p.hmr.sophos.com",
      "deployment.hubUrl = https://cloud.sophos.com")
    sed.write_file
  end
  only_if { node["sophos_cloud"]["context"] == "prod" }
end

ruby_block "replace_mongodb_with_mongos_in_mongoClient_setting" do
  block do
    # Bootstrap Properties
    btp = Chef::Util::FileEdit.new(bootstrap_file)
    btp.search_file_replace_line(
        "mongoClient.addresses *= *.*",
        "mongoClient.addresses = 127.0.0.1:#{mongos_net_port}")
    btp.write_file

    # Application Properties
    app = Chef::Util::FileEdit.new(application_file)
    app.search_file_replace_line(
        "mongoDb.cfg.addresses *= *.*",
        "mongoDb.cfg.addresses = 127.0.0.1:#{mongos_net_port}")
    app.write_file
  end
  only_if { node["sophos_cloud"]["sharding_enabled"] == "true" }
end

ruby_block "add_memcached_configuration_to_bootstrap_properties" do
  block do
    memcached_address = "memcached"
    memcached_address << ".#{node['sophos_cloud']['vpc_name']}".downcase
    memcached_address << ".#{node['ec2']['placement_availability_zone'].chop}".downcase
    memcached_address << ".#{node['sophos_cloud']['environment']}".downcase
    memcached_address << ".hydra.sophos.com"

    memcached_address_lookup = `nslookup #{memcached_address} | grep Name: | cut -f2 -d':'`.strip

    cache_cluster_id = "#{memcached_address_lookup}".split('.')[0]
    cache_cluster_port = '11211'
    region = node['sophos_cloud']['client-endpoint']

    describe_command = """
    aws elasticache describe-cache-clusters
      --show-cache-node-info
      --region #{region}
      --cache-cluster-id #{cache_cluster_id}
      --query 'CacheClusters[*].CacheNodes[*].Endpoint.Address'
      --output text
    """.gsub(/\s+/, ' ').strip

    memcached_addresses = `#{describe_command}`

    sed = Chef::Util::FileEdit.new(bootstrap_file)
    sed.insert_line_after_match('.*email.defaultSupport.*',"\nmemcached.enabled = #{node['memcached']['enabled']}\nmemcached.addresses = #{memcached_addresses.gsub(/\s+/, ":#{cache_cluster_port},").chop}\n")
    sed.write_file
  end
  only_if { is_java_app }
end

ruby_block "add_ssl_cert_hash_info_for_api" do
  block do
    cluster = node['sophos_cloud']['cluster']
    if cluster == 'api'
      keyHash = File.read("/etc/ssl/certs/#{node['cert']['api']}.sha256")

      sed = Chef::Util::FileEdit.new(bootstrap_file)
      sed.insert_line_if_no_match('uiSupport.publicKeyPins.(api)*',"\nuiSupport.publicKeyPins.(api) = #{keyHash}\n")
      sed.write_file
    end
  end
  only_if { is_java_app }
end

ruby_block "add_ssl_cert_hash_info_for_hub" do
  block do
    cluster = node['sophos_cloud']['cluster']
    if cluster == 'hub'
      keyHash = File.read("/etc/ssl/certs/#{node['cert']['hub']}.sha256")

      sed = Chef::Util::FileEdit.new(bootstrap_file)
      sed.insert_line_if_no_match('uiSupport.publicKeyPins.(hub)*',"\nuiSupport.publicKeyPins.(hub) = #{keyHash}\n")
      sed.write_file
    end
  end
  only_if { is_java_app }
end

ruby_block "set_webapp_version_tag" do
  block do
    region = node['sophos_cloud']['client-endpoint']

    # Get instance id.  If this fails something is seriously wrong.
    instance_id = `curl -f -s -S http://169.254.169.254/latest/meta-data/instance-id`
    if !$?.success?
      Chef::Log.fatal("failed to get instance-id")
      raise
    end

    # Get webapp version from META-INF/MANIFEST.MF in the war file.
    require "parseconfig"
    app_properties = ParseConfig.new("#{node['tomcat']['sophos_dir']}/application.properties")
    inst_type = node['sophos_cloud']['war_name']
    war_path = "#{node['tomcat']['webapp_dir']}/#{inst_type}.war"
    unzip_dir = "/tmp"
    zipped_manifest_mf_path = "META-INF/MANIFEST.MF"
    manifest_mf_path = "#{unzip_dir}/#{zipped_manifest_mf_path}"

    extract_command = "unzip #{war_path} #{zipped_manifest_mf_path} -o -d #{unzip_dir}".strip

    `#{extract_command}`

    verb = $?.success? ? "succeeded" : "failed"
    Chef::Log.info("extract manifest #{verb}: region #{region} instance #{instance_id}")

    # If we can't figure out the version it's not a critical error, is it?
    webapp_version = `awk '/^Implementation-Version:/ {print $2}' #{manifest_mf_path}`.strip
    Chef::Log.info("Read Implementation-Version '#{webapp_version}' from '#{manifest_mf_path}'")
    if !$?.success?
      Chef::Log.error("failed to extract Implementation-Version from '#{manifest_mf_path}'")
      webapp_version = 'Unknown'
    end

    create_command = """
    aws ec2 create-tags
      --region #{region}
      --resources #{instance_id}
      --tags Key=WebappVersion,Value=#{webapp_version}
    """.gsub(/\s+/, ' ').strip

    `#{create_command}`

    verb = $?.success? ? "succeeded" : "failed"
    Chef::Log.info("create-tags #{verb}: region #{region} instance #{instance_id} version #{webapp_version}")
  end
  only_if { is_java_app }
end

# as bootstrap.properties is placed in this cookbook and not in deploy recipe:
# add shared smc keystore secret to downloaded bootstrap.properties before tomcat start
# the secret from S3 was downloaded and assigned in deploy_cert

bootstrap_file = node['tomcat']['sophos_dir'] + "/bootstrap.properties"

ruby_block "Add smc shared secret in bootstrap.properties" do
  block do
    sed = Chef::Util::FileEdit.new(bootstrap_file)
    sed.insert_line_if_no_match('smc.sharedKeystorePassword*',"\nsmc.sharedKeystorePassword = #{node['temp']['smc']['key_passphrase']}\n")
    sed.write_file
  end
  only_if { node['sophos_cloud']['cluster'] == "smc" &&
      (defined?(node['temp']['smc']['key_passphrase']) && node['temp']['smc']['key_passphrase']) }
end

if "#{node['sophos_cloud']['cluster']}" == 'api'
  bash "download public gateway shared_token" do
    user "root"
    cwd "/tmp"
    code <<-EOH
      set -e

      aws configure set default.s3.signature_version s3v4

       #{node['sophos_cloud']['script_path']}/download-object #{node['sophos_cloud']['environment']} \
                        #{node['sophos_cloud']['connections']} \
                        #{node['sophos_cloud']['gateway_pass']} \
                        #{sophos_tmp_path}/#{node['sophos_cloud']['gateway_pass']} || true
    EOH
    ignore_failure true
  end

  bash "upload_shared_token" do
    not_if { ::File.exists?("#{sophos_tmp_path}/#{node['sophos_cloud']['gateway_pass']}") }
    user "root"
    cwd "/tmp"
    code <<-EOH
      set -e
      SHARED_TOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
      echo -n $SHARED_TOKEN > "#{sophos_tmp_path}/#{node['sophos_cloud']['gateway_pass']}"
      aws configure set default.s3.signature_version s3v4

       #{node['sophos_cloud']['script_path']}/upload-object \
                        #{node['sophos_cloud']['environment']} \
                        #{node['sophos_cloud']['vpc_name']}  \
                        #{node['sophos_cloud']['region']} \
                        #{node['sophos_cloud']['connections']} \
                        #{node['sophos_cloud']['gateway_pass']} \
                        #{sophos_tmp_path}/#{node['sophos_cloud']['gateway_pass']} || true
    EOH
  end

  ruby_block "set public gateway shared token" do
    block do
      gateway_shared_token = File.read("#{sophos_tmp_path}/#{node['sophos_cloud']['gateway_pass']}").strip

      sed = Chef::Util::FileEdit.new(bootstrap_file)
      sed.insert_line_if_no_match('gatewaySecurity.sharedToken*',"\ngatewaySecurity.sharedToken = #{gateway_shared_token}\n")
      sed.write_file
    end
  end

  file "#{sophos_tmp_path}/#{node['sophos_cloud']['gateway_pass']}" do
    action :delete
    only_if { File.exist? "#{sophos_tmp_path}/#{node['sophos_cloud']['gateway_pass']}" }
  end

end

service "postfix" do
  action [ :enable, :start]
  only_if { node['email']['install'] == "yes" }
end

# Replace nginx.conf with environment-specific configuration
template "nginx.conf" do
  path "/etc/nginx/nginx.conf"
  source "nginx.conf.erb"
  variables({
                :domain =>  mail_domain
            })
  mode "0644"
  owner "nginx"
  group "nginx"
end

# Remove nginx file from logrotate.d directory as it conflicts with ours
file "/etc/logrotate.d/nginx" do
  action :delete
end

