default['newrelic']['enabled'] = 'false'

default['newrelic']['version'] = '8.5.69'

default['newrelic']['owner'] = 'newrelic'
default['newrelic']['group'] = 'newrelic'

# The newrelic-infra.yml has to be located either at '/etc/newrelic-infra.yml' or '/etc/newrelic-infra/newrelic-infra.yml'
# There is no way to override this location without manually installing a tarball and doing a lot more configuration work
default['newrelic']['infra']['version'] = '1.17.1-1.el7'
default['newrelic']['infra']['bin_location'] = '/etc/newrelic-infra/bin'
default['newrelic']['infra']['log_location'] = '/var/log/newrelic-infra'
default['newrelic']['infra']['conf_location'] = '/etc/newrelic-infra'
default['newrelic']['infra']['integrations']['conf_location'] = '/etc/newrelic-infra/integrations.d'

default['newrelic']['infra']['storage_metrics']['sample_rate'] = 120
default['newrelic']['infra']['system_metrics']['sample_rate'] = 120
default['newrelic']['infra']['network_metrics']['sample_rate'] = 120
default['newrelic']['infra']['process_metrics']['enable'] = 'true'
default['newrelic']['infra']['process_metrics']['sample_rate'] = 120
default['newrelic']['infra']['process_metrics']['naming_patterns'] = [
    "^newrelic@sophos$",
    "^savdid$",
    "^systemd$",
    "^td-agent",
    "^java",
    "^postfix",
    "^jilter",
    "^sqsmsgproducer",
    "^sqsmsgconsumer"
]
