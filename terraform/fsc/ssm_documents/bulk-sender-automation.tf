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

# ----------------------------------------------------
# SSM Automation IAM Role and Policies
# ----------------------------------------------------

resource "aws_iam_role" "bulk_sender_automation_role" {
  name = "bulk_sender_automation_role"
  assume_role_policy = data.aws_iam_policy_document.bulk_sender_automation_trust_policy.json
}

data "aws_iam_policy_document" "bulk_sender_automation_trust_policy" {
  policy_id = "bulk_sender_automation_trust_policy"

  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ssm.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "bulk_sender_automation_policy" {
  policy_id = "bulk_sender_automation_policy"

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid = "Ec2Permissions"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "CloudWatchLogGroup"
    actions = [
      "logs:CreateLogGroup",
    ]
    effect    = "Allow"
    resources = [
      "arn:aws:logs:${local.input_param_primary_region}:*:*"
    ]
  }
  statement {
    sid = "CloudWatchLogStream"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect    = "Allow"
    resources = [
      "arn:aws:logs:${local.input_param_primary_region}:*:log-group:*:*"
    ]
  }
  statement {
    sid = "SsmAutomationPermissions"
    effect = "Allow"
    actions = [
      "ssm:DescribeAutomationExecutions",
      "ssm:DescribeAutomationStepExecutions",
      "ssm:DescribeDocument",
      "ssm:DescribeInstanceInformation",
      "ssm:GetAutomationExecution",
      "ssm:GetCommandInvocation",
      "ssm:GetConnectionStatus",
      "ssm:GetDocument",
      "ssm:ListCommandInvocations",
      "ssm:ListCommands",
      "ssm:ListInstanceAssociations",
      "ssm:ListDocuments",
      "ssm:ListDocumentVersions",
      "ssm:SendCommand",
      "ssm:StartAutomationExecution",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "bulk_sender_automation_policy" {
  name   = "bulk-sender-automation-policy"
  role   = aws_iam_role.bulk_sender_automation_role.id
  policy = data.aws_iam_policy_document.bulk_sender_automation_policy.json
}
