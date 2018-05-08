cookbook_file "test.txt" do
  path "/tmp/text.txt"
  source "text.txt"
  mode 0777
  owner "root"
  group "root"
end