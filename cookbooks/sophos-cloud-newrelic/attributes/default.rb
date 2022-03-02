
COMPRESSIBLE_MIME_TYPES = [
    'application/javascript',
    'application/json',
    'application/vnd.sophos-compressed+json',
    'text/css',
    'text/html',
    'text/javascript',
    'text/plain',
    'text/xml'
  ].join(',')

CONNECTOR_TEMPLATE = 'connector-fragment.xml.erb'
CONNECTOR_COOKBOOK = 'sophos_tomcat'

CIPHER_SPEC = [
    'ALL+HIGH', # We want only high grade ciphers (128+ bits)
    '!aNULL',   # No NULL ciphers
    '!eNULL',
    '!3DES',    # Triple DES is cracked
    '!DH',
    '!RC4',     # Thankfully no need to run under Windows XP
    '!SSLv2',   # SSLv2 is cracked
    '@STRENGTH' # Sort by cipher strength
  ].join(':')

EXECUTOR_NAME = 'tomcat-thread-pool'
HTTP_PORT = '8080'
HTTPS_PORT = '8443'

default['tomcat']['version'] = '8.5.69'

default['tomcat']['owner'] = 'tomcat'
default['tomcat']['group'] = 'tomcat'

default['tomcat']['context_path'] = 'invalid'

default['tomcat']['configuration_branch'] = nil

default['tomcat']['config_bucket_override'] = nil
default['tomcat']['config_bucket_region_override'] = nil

default['tomcat']['connector']['cipher_spec'] = CIPHER_SPEC
default['tomcat']['connector']['compressible_mime_types'] = COMPRESSIBLE_MIME_TYPES

default['tomcat']['connector']['template'] = CONNECTOR_TEMPLATE
default['tomcat']['connector']['cookbook'] = CONNECTOR_COOKBOOK

default['tomcat']['http_port'] = HTTP_PORT
default['tomcat']['https_port'] = HTTPS_PORT

default['tomcat']['executor_name'] = EXECUTOR_NAME

default['tomcat']['is_local_artifact'] = true

default['tomcat']['jmx_remote_port'] = '1099'

default['tomcat']['post_config_bundle_entry_point_recipe'] = nil
default['tomcat']['runtime_entry_point_recipe'] = 'sophos_tomcat::runtime'

default['tomcat']['service_sub_name'] = 'sophos'
# Comma-separated list of Spring profiles to activate
default['tomcat']['spring_profiles'] = [
    'aws'
  ].join(',')

default['tomcat']['war_artifact_id'] = nil
default['tomcat']['war_version'] = nil

default['tomcat']['perf']['heap_memory_percentage'] = 0.75
default['tomcat']['perf']['memory_per_thread_mibs'] = 4
# Keep nonheap_resident_memory_mibs <= 1246 to avoid adding swap to instances with 8GiB RAM.
default['tomcat']['perf']['nonheap_resident_memory_mibs'] = 1024
default['tomcat']['perf']['open_file_limit'] = '32768'
default['tomcat']['perf']['stack_size'] = '384k'
# Needs to be a string to pass through Packer.
default['tomcat']['perf']['thread_limit'] = '2200'

default['tomcat']['security']['keystore_create_vars'] = nil
default['tomcat']['security']['keystore_file'] = 'tomcat-keystore.p12'
default['tomcat']['security']['keystore_type'] = 'PKCS12'
default['tomcat']['security']['keystore_password_property'] = 'tomcat.keystore.password'

default['tomcat']['security']['truststore_create_vars'] = nil
default['tomcat']['security']['truststore_file'] = 'tomcat-truststore.p12'
default['tomcat']['security']['truststore_type'] = 'PKCS12'
default['tomcat']['security']['truststore_password_property'] = 'tomcat.truststore.password'

default['tomcat']['server_cert']['cert_file'] = nil
default['tomcat']['server_cert']['intermediary_cert_chain_file'] = nil
default['tomcat']['server_cert']['key_file'] = nil

# Put all the newrelic agents under the same root directory: '/etc'
# Note, it would nice to have kept the root as '/opt' but we're restricted by the infra agent configuration.
default['newrelic']['apm']['artifact_id'] = 'newrelic-agent'
default['newrelic']['apm']['destination'] = '/etc/newrelic-apm'
default['newrelic']['apm']['log_location'] = '/var/log/newrelic-apm'
default['newrelic']['apm']['version'] = '7.4.2'

# The newrelic-infra.yml has to be located either at '/etc/newrelic-infra.yml' or '/etc/newrelic-infra/newrelic-infra.yml'
# There is no way to override this location without manually installing a tarball and doing a lot more configuration work
default['newrelic']['infra']['bin_location'] = '/etc/newrelic-infra/bin'
default['newrelic']['infra']['conf_location'] = '/etc/newrelic-infra'
default['newrelic']['infra']['integrations']['conf_location'] = '/etc/newrelic-infra/integrations.d'
default['newrelic']['infra']['jmx']['collection_files']['names'] = [
    'jvm-metrics.yml',
    'tomcat-metrics.yml'
]
default['newrelic']['infra']['jmx']['collection_files']['location'] = "/etc/newrelic-infra/jmx"
default['newrelic']['infra']['jmx']['sample_rate'] = 60
default['newrelic']['infra']['jmx']['version'] = '2.4.5-1'
default['newrelic']['infra']['nrjmx']['version'] = '1.7.0-1'
default['newrelic']['infra']['network_metrics']['sample_rate'] = 120
default['newrelic']['infra']['process_metrics']['enable'] = 'true'
default['newrelic']['infra']['process_metrics']['sample_rate'] = 120
default['newrelic']['infra']['process_metrics']['naming_patterns'] = [
    "^tomcat@sophos$",
    "^savdid$",
    "^systemd$",
    "^dockerd$",
    "^java",
    "^mongo",
    "^kinesis"
]
default['newrelic']['infra']['prometheus']['jmx']['conf_location'] = "/opt/prometheus/jmx/conf"
default['newrelic']['infra']['prometheus']['version'] = '0.15.0'
default['newrelic']['infra']['prometheus']['destination'] = "/opt/prometheus/jmx/bin"
default['newrelic']['infra']['prometheus']['port'] = '8081'

default['newrelic']['infra']['log_forwarding']['conf_location'] = '/etc/newrelic-infra/logging.d'
default['newrelic']['infra']['log_location'] = '/var/log/newrelic-infra'
default['newrelic']['infra']['storage_metrics']['sample_rate'] = 120
default['newrelic']['infra']['system_metrics']['sample_rate'] = 120
default['newrelic']['infra']['version'] = '1.17.1-1.el7'

default['newrelic']['tags']['sophos_project'] = 'sophos-cloud'

default['sealights']['artifact_id'] = 'sl-test-listener'
default['sealights']['destination'] = '/opt/sealights'
default['sealights']['lab_id'] = 'sophos_cloud_integration'
default['sealights']['log_location'] = '/var/log/sealights'
default['sealights']['log_enabled'] = 'true'
default['sealights']['log_level'] = 'info'
default['sealights']['log_to_file'] = 'true'
default['sealights']['session_id_file'] = 'buildSessionId.txt'
default['sealights']['token_file'] = 'sltoken.txt'
default['sealights']['version'] = '3.1.1892'

# Put all the sqreen agents under the same root directory: '/opt'
default['sqreen']['artifact_id'] = 'sqreen'
default['sqreen']['destination'] = '/opt/sqreen'
default['sqreen']['version'] = '0.12.1'
default['sqreen']['appname'] = 'Central'

default['app']['security']['truststore_file'] = 'application-truststore.p12'
default['app']['security']['truststore_type'] = 'PKCS12'
default['app']['security']['truststore_password_property'] = 'sophos.truststore.password'

default['dynatrace']['artifact_id'] = 'dynatrace-oneagent-linux'
default['dynatrace']['artifact']['repository'] = 'generic'
default['dynatrace']['install']['location'] = '/opt/dynatrace'
default['dynatrace']['version'] = '1.199.101'

default['cmd']['destination'] = '/etc/cmd'
default['cmd']['servergroup'] = 'central'
default['cmd']['version'] = '1.4.6'

default['tomcat']['connector_vars'] = [
  {
    template: CONNECTOR_TEMPLATE,
    template_cookbook: CONNECTOR_COOKBOOK,
    variables: {
      compressible_mime_types: COMPRESSIBLE_MIME_TYPES,
      connector_scheme: 'http',
      has_ssl_config: false,
      is_secure: false,
      port: HTTP_PORT,
      tomcat_executor_name: EXECUTOR_NAME
    }
  }
]
