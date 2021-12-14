# vim: autoindent expandtab shiftwidth=2 filetype=terraform
resource "aws_ssm_document" "ssm_update_hostname" {
  name          = "ssm-update-hostname"
  document_type = "Command"
  content = <<DOC
  {
    "schemaVersion": "2.2",
    "description": "Update the hostname on an EC2 instance",
    "parameters": {
      "hostname": {
        "type":"String",
        "description":"The hostname of the ec2 instance."
      }
    },
    "mainSteps": [
      {
        "action":"aws:runShellScript",
        "name":"runShellScript",
        "inputs":{
          "runCommand":[
            "postmulti -i $(postmulti -l | grep -v '^-' | awk '{print $1}') -x postconf myhostname={{ hostname }}",
            "monit start postfix"
          ]
        }
      }
    ]
  }
DOC
}
