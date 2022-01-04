# vim: autoindent expandtab shiftwidth=2 filetype=terraform
locals {
  ssm_postconf_command_ssm_document = {
    "schemaVersion": "2.2",
    "description": "Run any Postmulti/Postconf command on any instance",
    "parameters": {
      "Parameter": {
        "type":"String",
        "description":"The Postfix configuration Parameter."
      },
      "Value": {
        "type":"String",
        "description":"The Postfix configuration Parameter Value."
      }
    },
    "mainSteps": [
      {
        "action":"aws:runShellScript",
        "name":"runShellScript",
        "inputs":{
          "runCommand":[
            "postmulti -i $(postmulti -l | grep -v '^-' | awk '{print $1}') -x postconf -e {{ Parameter }}='{{ Value }}'"
          ]
        }
      }
    ]
  }
}

resource "aws_ssm_document" "ssm_postconf_command" {
  name          = "ssm-postconf-command"
  document_type = "Command"
  content = jsonencode(local.ssm_postconf_command_ssm_document)
}
