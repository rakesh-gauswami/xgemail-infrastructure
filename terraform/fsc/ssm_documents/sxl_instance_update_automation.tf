# vim: autoindent expandtab shiftwidth=2 filetype=terraform
resource "aws_ssm_document" "sxl_instance_update_automation" {
  name          = "sxl-instance-update-automation"
  document_type = "Automation"

  content = <<DOC
  {
    "schemaVersion": "0.3",
    "assumeRole": "{{assumeRole}}",
    "description": "Update Postfix configuration on an EC2 instance in an AutoScaling Group.",
    "parameters": {
      "assumeRole": {
        "type": "String",
        "description": "Role under which to run the automation",
        "default": ""
      },
      "InstanceType": {
        "type": "String",
        "description": "The EC2 Instance Type.",
        "allowedValues": [
          "internet-submit",
          "customer-submit"
        ]
      },
      "SxlCurrent": {
        "type": "String",
        "description": "The Postfix parameter to update."
      },
      "SxlUpdate": {
        "type": "String",
        "description": "The Postfix parameter value."
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
            },
            {
              "Name": "tag:sxl-revision",
              "Values": [
                "{{SxlCurrent}}"
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
        "nextStep": "PostfixConfig"
      },
      {
        "name": "PostfixConfig",
        "action": "aws:runCommand",
        "maxAttempts": 3,
        "timeoutSeconds": 3600,
        "inputs": {
          "DocumentName": "AWS-RunShellScript",
          "InstanceIds": [ "{{getInstance.InstanceId}}" ],
          "Parameters": {
            "commands": [
              "postmulti -i $(postmulti -l | grep -v '^-' | awk '{print $1}') -x postconf reject_rbl_client='$reject_rbl_client_{{SxlUpdate}}'",
              "postmulti -i $(postmulti -l | grep -v '^-' | awk '{print $1}') -x postconf rbl_reply_maps=hash:/etc/$(postmulti -l | grep -v '^-' | awk '{print $1}')/rbl_reply_maps_{{SxlUpdate}}",
              "postmulti -i $(postmulti -l | grep -v '^-' | awk '{print $1}') -p reload"
            ]
          }
        },
        "nextStep": "tagInstance"
      },
      {
        "name": "tagInstance",
        "action": "aws:executeAutomation",
        "maxAttempts": 3,
        "timeoutSeconds": 3600,
        "isEnd": "true",
        "onFailure": "Abort",
        "inputs": {
          "DocumentName": "${aws_ssm_document.tag_instance_automation.name}",
          "RuntimeParameters": {
            "InstanceId": "{{getInstance.InstanceId}}",
            "Tag": "sxl-revision",
            "Value": "{{SxlUpdate}}"
          }
        }
      }
    ]
  }
DOC
}
