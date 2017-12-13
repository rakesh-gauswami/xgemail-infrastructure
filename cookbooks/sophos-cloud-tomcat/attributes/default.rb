#
# Cookbook Name:: sophos-cloud-tomcat
# Attribute:: default
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Sophos
default['sophos_cloud']['application']                  = "//cloud-applications/develop/core-services.war"
default['sophos_cloud']['cluster']                      = "core"
default['sophos_cloud']['configs']                      = "//cloud-dev-configs"
default['sophos_cloud']['connections']                  = "//cloud-dev-connections"
# annoying that we use both of these... imported recipes require environment -- we should standardize
default['sophos_cloud']['environment']                  = "dev"
default['sophos_cloud']['context']                      = "dev"
#
default['sophos_cloud']['cookbooks']                    = "//cloud-dev-cookbooks/cookbooks.tar.gz"
default['sophos_cloud']['domain']                       = "p0.d.hmr.sophos.com"
default['sophos_cloud']['is_java_app']                  = "yes"
default['sophos_cloud']['java']                         = "#{node['sophos_cloud']['thirdparty']}/jdk.tar.gz"
default['sophos_cloud']['local_cert_path']              = "/etc/ssl/certs"
default['sophos_cloud']['local_key_path']               = "/etc/ssl/private"
default['sophos_cloud']['public_stac_bucket']           = "public-cloud-#{node['sophos_cloud']['context']}-eu-west-1-#{node['sophos_cloud']['vpc_name']}-stac"
default['sophos_cloud']['script_path']                  = "/var/sophos/scripts"
default['sophos_cloud']['thirdparty']                   = "//cloud-dev-3rdparty"
default['sophos_cloud']['tmp']                          = "/tmp/sophos"
default['sophos_cloud']['tomcat']                       = "#{node['sophos_cloud']['thirdparty']}/tomcat.tar.gz"
default['sophos_cloud']['tcell']                        = "tcell-jvmagent-0.3.4-DEV.tar.gz"
default['sophos_cloud']['vpc_name']                     = 'CloudStation'
default['sophos_cloud']['gateway_pass']                 = 'gateway-pass'

# Certificate names
default['cert']['default']                              = "hydra.sophos.com"
default['cert']['api']                                  = "hmr-mcs"
default['cert']['core']                                 = "hmr-iapi"
default['cert']['csg']                                  = "hydra.sophos.com"
default['cert']['dep']                                  = "dep-services"
default['cert']['hub']                                  = "hub-services"
default['cert']['mcs']                                  = "hmr-mcs"
default['cert']['mob']                                  = "hmr-mob"
default['cert']['mx']                                   = "mx"
default['cert']['smc']['signing']                       = "smc-message-signing"
default['cert']['utm']                                  = "hmr-utm"
default['cert']['wifi']                                 = "hmr-wifi"
default['cert']['should_install_mx']                    = false

# Tomcat settings
default['tomcat']['client_cert_store']                  = "/data/clientCertStore/"
default['tomcat']['etc_dir']                            = "/data/etc"
default['tomcat']['heap_initial']                       = "1024m"
default['tomcat']['heap_max']                           = "#{((node['memory']['total'].to_i / 1024) * 0.75).to_i}m"  # Use 75% of ram as max size
default['tomcat']['keystore_pass']                      = "change me bro"
default['tomcat']['log_dir']                            = "/data/log/tomcat"
default['tomcat']['dir']                                = "/usr/share/tomcat"
default['tomcat']['logging_conf_filename']              = "logback.xml"
default['tomcat']['pid_dir']                            = "/var/run/tomcat"
default['tomcat']['pid_file']                           = "#{default['tomcat']['pid_dir']}/tomcat.pid"
default['tomcat']['should_update_keystore']             = true
default['tomcat']['sophos_dir']                         = "/usr/local/etc/sophos"
default['tomcat']['spring_profiles']                    = "aws"
default['tomcat']['start_command']                      = "service tomcat start"
default['tomcat']['stop_command']                       = "test -r #{default['tomcat']['pid_file']} && service tomcat stop 30 -force || true"
default['tomcat']['thread_max']                         = "#{default['tomcat']['heap_max'].to_i / 4 < 2200 ? default['tomcat']['heap_max'].to_i / 4 : 2200}"
default['tomcat']['tmp_dir']                            = "/data/tmp"
default['tomcat']['webapp_dir']                         = "/data/var/webapps"

# Postfix settings
default['email']['install']                             = "yes"
default['email']['key_filename']                        = "smtp-client"
default['email']['mail_domain']                         = "sophos.com"
default['email']['mail_name']                           = "mail"
default['email']['mail_version']                        = "mail_version"

# Mongo Settings
default['mongo']['mongos_net_port']                     = "27018"

# SAML settings
default['saml']['keystore_alias']                       = "SOPHOS:SAML"
default['saml']['keystore_location']                    = "/usr/local/etc/sophos/samlKeystore.jks"
default['saml']['keystore_password']                    = "saml_keystore_pass"
