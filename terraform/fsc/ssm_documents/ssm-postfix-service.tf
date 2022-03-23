# vim: autoindent expandtab shiftwidth=2 filetype=terraform
locals {
  ssm_postfix_service_ssm_document = {
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
}

resource "aws_ssm_document" "ssm_postfix_service" {
  name          = "ssm-postfix-service"
  document_type = "Command"
  content = jsonencode(local.ssm_postfix_service_ssm_document)
}
