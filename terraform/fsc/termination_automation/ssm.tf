# vim: autoindent expandtab shiftwidth=2 filetype=terraform
locals {
  ssm_document = {
    "schemaVersion": "0.3",
    "assumeRole": "${aws_iam_role.termination_automation_role.arn}",
    "description": "Safe shutdown of an EC2 instance",
    "parameters": {
      "Region": {
        "type":"String",
        "description":"The AWS Region."
      },
      "Time": {
        "type":"String",
        "description":"The timestamp on the Lifecycle Hook."
      },
      "AutoScalingGroupName": {
        "type":"String",
        "description":"The AutoScaling Group Name."
      },
      "InstanceId": {
        "type":"String",
        "description":"The EC2 Instance Id."
      },
      "LifecycleHookName": {
        "type":"String",
        "description":"The Lifecycle Hook Name."
      },
      "LifecycleActionToken": {
        "type":"String",
        "description":"The Lifecycle Action Token."
      }
    },
    "mainSteps": [
      {
        "name": "getInstanceDeleteOnTermination",
        "action": "aws:executeAwsApi",
        "maxAttempts": 3,
        "timeoutSeconds": 60,
        "inputs": {
          "Service": "ec2",
          "Api": "DescribeInstances",
          "InstanceIds": [
            "{{ InstanceId }}"
          ]
        },
        "outputs": [
          {
            "Name": "DeleteOnTermination",
            "Selector": "$.Reservations[0].Instances[0].BlockDeviceMappings[4].Ebs.DeleteOnTermination",
            "Type": "Boolean"
          }
        ],
        "nextStep": "branchOnDeleteOnTermination",
        "onFailure": "Continue"
      },
      {
        "name": "branchOnDeleteOnTermination",
        "action": "aws:branch",
        "inputs": {
          "Choices": [
            {
              "NextStep": "getVolumeId",
              "Variable": "{{ getInstanceDeleteOnTermination.DeleteOnTermination }}",
              "BooleanEquals": false
            }
          ]
        },
        "isEnd": true
      },
      {
        "name": "getVolumeId",
        "action": "aws:executeAwsApi",
        "maxAttempts": 3,
        "timeoutSeconds": 60,
        "inputs": {
          "Service": "ec2",
          "Api": "DescribeVolumes",
          "Filters": [
            {
              "Name": "attachment.instance-id",
              "Values": [ "{{InstanceId}}" ]
            },
            {
              "Name": "attachment.device",
              "Values": [ "/dev/xvdi" ]
            }
          ]
        },
        "outputs": [
          {
            "Name": "VolumeId",
            "Selector": "$.Volumes[0].Attachments[0].VolumeId",
            "Type": "String"
          }
        ],
        "nextStep": "terminationAutomation",
        "onFailure": "Continue"
      },
      {
        "name": "terminationAutomation",
        "action": "aws:runCommand",
        "maxAttempts": 1,
        "inputs": {
          "DocumentName": "AWS-RunShellScript",
          "InstanceIds": [ "{{InstanceId}}" ],
          "Parameters": {
            "timeoutSeconds": "172800",
            "commands": [
              "/opt/sophos/xgemail/instance-terminator.py -r {{Region}} -t {{Time}} -a {{AutoScalingGroupName}} -i {{InstanceId}} -l {{LifecycleHookName}} -k {{LifecycleActionToken}}"
            ]
          }
        },
        "nextStep": "volumeEmpty",
        "onFailure": "step:volumeNotEmpty"
      },
      {
        "name": "volumeNotEmpty",
        "action": "aws:executeAwsApi",
        "maxAttempts": 3,
        "timeoutSeconds": 60,
        "inputs": {
          "Service": "autoscaling",
          "Api": "CompleteLifecycleAction",
          "AutoScalingGroupName": "{{AutoScalingGroupName}}",
          "InstanceId": "{{InstanceId}}",
          "LifecycleActionResult": "CONTINUE",
          "LifecycleActionToken": "{{LifecycleActionToken}}",
          "LifecycleHookName": "{{LifecycleHookName}}"
        },
        "nextStep": "sendAlert",
        "onFailure": "Continue"
      },
      {
        "name": "sendAlert",
        "action": "aws:executeAwsApi",
        "maxAttempts": 3,
        "timeoutSeconds": 60,
        "inputs": {
          "Service": "sns",
          "Api": "Publish",
          "TopicArn": "${local.input_param_alarm_topic_arn}",
          "Subject": "Undelivered messages stuck in email queue on Volume Id {{getVolumeId.VolumeId}}",
          "Message": "Region: {{Region}} Volume Id: {{getVolumeId.VolumeId}} EC2 Instance: {{InstanceId}}"
        },
        "isEnd": true
      },
      {
        "name": "volumeEmpty",
        "action": "aws:executeAwsApi",
        "maxAttempts": 3,
        "timeoutSeconds": 60,
        "inputs": {
          "Service": "autoscaling",
          "Api": "CompleteLifecycleAction",
          "AutoScalingGroupName": "{{AutoScalingGroupName}}",
          "InstanceId": "{{InstanceId}}",
          "LifecycleActionResult": "CONTINUE",
          "LifecycleActionToken": "{{LifecycleActionToken}}",
          "LifecycleHookName": "{{LifecycleHookName}}"
        },
        "nextStep": "describeVolume",
        "onFailure": "Continue"
      },
      {
        "name": "describeVolume",
        "action": "aws:waitForAwsResourceProperty",
        "timeoutSeconds": 120,
        "inputs": {
          "Service": "ec2",
          "Api": "DescribeVolumes",
          "VolumeIds": [ "{{getVolumeId.VolumeId}}" ],
          "PropertySelector": "$.Volumes[0].State",
          "DesiredValues": [ "available" ]
        },
        "nextStep": "deleteVolume",
        "onFailure": "Continue"
      },
      {
        "name": "deleteVolume",
        "action": "aws:executeAwsApi",
        "maxAttempts": 3,
        "timeoutSeconds": 60,
        "inputs": {
          "Service": "ec2",
          "Api": "DeleteVolume",
          "VolumeId": "{{getVolumeId.VolumeId}}"
        },
        "isEnd": true
      }
    ],
    "outputs": [
      "getVolumeId.VolumeId",
      "getInstanceDeleteOnTermination.DeleteOnTermination"
    ]
  }
}

resource "aws_ssm_document" "termination_automation" {
  name          = "termination-automation"
  document_type = "Automation"

  content = jsonencode(local.ssm_document)
}
