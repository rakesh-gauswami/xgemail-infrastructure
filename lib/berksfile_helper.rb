def opsworks_cookbook(name)
  cookbook name, path: File.expand_path("../../vendor-cookbooks/opsworks-cookbooks/#{name}", __FILE__)
end

def vendor_cookbook(name, folder_name=nil)
  folder_name ||= name
  cookbook name, path: File.expand_path("../../vendor-cookbooks/#{folder_name}", __FILE__)
end

def sophos_cookbook(name, folder_name=nil)
  folder_name ||= name
  cookbook name, path: File.expand_path("../cookbooks/#{folder_name}", __FILE__)
end
