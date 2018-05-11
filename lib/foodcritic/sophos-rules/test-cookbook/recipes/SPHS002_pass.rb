execute "passing_command" do
  command "aws s3 cp local_file.txt s3://s3_bucket_name/"
end

bash "passing_command" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  aws s3 cp local_file.txt s3://s3_bucket_name/
  EOH
end