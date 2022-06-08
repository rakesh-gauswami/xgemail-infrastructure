# vim: autoindent expandtab shiftwidth=2 filetype=terraform
locals {
  bulk_sender_automation_ssm_document = {
    "schemaVersion": "0.3",
    "assumeRole": "${aws_iam_role.bulk_sender_automation_role.arn}",
    "description": "Execute BulkSender PythonScript",
    "parameters": {
      "assumeRole": {
        "type":"String",
        "description": "Role under which to run the automation.",
        "default": ""
      },
      "InstanceType": {
        "type":"String",
        "description": "The EC2 Instance Type.",
        "allowedValues": [
          "customer-submit"
        ]
      }
    },
    "mainSteps": [
      {
        "name": "getInstance",
        "action": "aws:executeAwsApi",
        "maxAttempts": 3,
        "onFailure": "Abort",
        "inputs": {
          "Service": "ec2",
          "Api": "DescribeInstances",
          "Filters": [
            {
              "Name": "tag:Application",
              "Values": [
                "{{InstanceType}}"
              ]
            },
            {
              "Name": "instance-state-name",
              "Values": [
                "running"
              ]
            }
          ]
        },
        "outputs": [
          {
            "Name": "InstanceId",
            "Selector": "$.Reservations[0].Instances[0].InstanceId",
            "Type": "String"
          }
        ],
        "isCritical": "true",
        "nextStep": "RunRateLimitScript"
      },
      {
        "name": "RunRateLimitScript",
        "action": "aws:runCommand",
        "maxAttempts": 3,
        "timeoutSeconds": 30,
        "inputs": {
          "DocumentName": "AWS-RunShellScript",
          "InstanceIds": [ "{{getInstance.InstanceId}}" ],
          "Parameters": {
            "commands": [
              "/opt/sophos/xgemail/xgemail-bulksender-service/xgemail.bulksender.merger.py"
            ]
          }
        }
      }
    ]
  }
}

resource "aws_ssm_document" "bulk_sender_automation" {
  name          = "bulk-sender-automation"
  document_type = "Automation"

  content = jsonencode(local.bulk_sender_automation_ssm_document)
}
