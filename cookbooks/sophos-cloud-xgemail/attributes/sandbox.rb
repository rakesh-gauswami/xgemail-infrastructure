# Sandbox settings
env = ENV['DEFAULT_ENVIRONMENT']
if env == "sandbox"
  default['sophos_cloud']['region']      = ENV['DEFAULT_REGION']
  default['sophos_cloud']['environment'] = ENV['DEFAULT_ENVIRONMENT']
  default['xgemail']['cluster_type']     = ENV['INSTANCE_TYPE']
  default['xgemail']['sxl_dbl']          = 'fake-domain.com'
  default['xgemail']['sxl_rbl']          = 'fake-domain.com'
end