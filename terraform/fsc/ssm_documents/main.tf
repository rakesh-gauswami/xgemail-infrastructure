# vim: autoindent expandtab shiftwidth=2 filetype=terraform
resource "aws_ssm_document" "ssm_postfix_service" {
  name          = "ssm-postfix-service"
  document_type = "Command"
  content = <<DOC
  {
      "schemaVersion": "2.2",
      "description": "Start or Stop Postfix Service via Monit Service",
      "parameters": {
        "cmd": {
          "type":"String",
          "description":"Start or stop Postfix."
        }
      },
      "mainSteps": [
        {
          "action":"aws:runShellScript",
          "name":"runShellScript",
          "inputs":{
            "runCommand":[
              "monit {{ cmd }} postfix"
            ]
          }
        }
      ]
    }
DOC
}

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
