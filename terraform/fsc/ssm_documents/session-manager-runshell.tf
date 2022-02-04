# vim: autoindent expandtab shiftwidth=2 filetype=terraform
locals {
  session_manager_runshell_ssm_document = {
    "schemaVersion": "1.0",
    "description": "Document to hold regional settings for Session Manager",
    "sessionType": "Standard_Stream",
    "inputs": {
      "s3BucketName": "",
      "s3KeyPrefix": "",
      "s3EncryptionEnabled": true,
      "cloudWatchLogGroupName": "",
      "cloudWatchEncryptionEnabled": true,
      "idleSessionTimeout": "60",
      "maxSessionDuration": "1440",
      "cloudWatchStreamingEnabled": true,
      "kmsKeyId": "",
      "runAsEnabled": true,
      "runAsDefaultUser": "ec2-user",
      "shellProfile": {
        "windows": "",
        "linux": "/bin/bash\nsudo -i\nexport INSTANCE_ID=$(curl -fs http://169.254.169.254/latest/meta-data/instance-id)\nexport REGION=$(curl -fs http://169.254.169.254/latest/meta-data/placement/region)\nexport APPLICATION=$(aws ec2 describe-tags --region ${REGION} --filters \"Name=resource-id,Values=${INSTANCE_ID}\" | jq -r '.Tags[] | select(.Key == \"Application\").Value')\nPS1=\"\\[\\033[01;32m\\]\\u\\[\\033[01;33m\\]@\\[\\033[01;35m\\]\\$APPLICATION\\[\\033[01;36m\\]:\\[\\033[01;34m\\]\\w\\[\\033[01;31m\\]\\$\\[\\033[0m\\] \"\nalias cheflog='less +F /var/log/chef-client.instance.install.service.log'\nalias cfninitlog='less +F /var/log/cfn-init.log'\nalias tdlog='less +F /var/log/td-agent/td-agent.log'\nclear"
      }
    }
  }
}

resource "aws_ssm_document" "session_manager_runshell" {
  name          = "SSM-SessionManagerRunShell"
  document_type = "Session"
  content = jsonencode(local.session_manager_runshell_ssm_document)
}
