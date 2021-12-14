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
