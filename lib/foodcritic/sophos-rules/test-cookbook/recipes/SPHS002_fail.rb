execute "failing_command" do
  command "s3cmd get s3://BUCKET/OBJECT LOCAL_FILE"
end

bash "failing_command" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  s3cmd get s3://BUCKET/OBJECT LOCAL_FILE
  EOH
end
