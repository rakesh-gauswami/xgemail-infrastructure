# vim: autoindent expandtab shiftwidth=2 filetype=terraform
locals {
  postfix_sxl_update_automation_ssm_document = {
    "schemaVersion": "0.3",
    "assumeRole": "${aws_iam_role.postfix_sxl_update_automation_role.arn}",
    "description": "Update Postfix configuration on an EC2 instance in an AutoScaling Group.",
    "parameters": {
      "InstanceType": {
        "type":"String",
        "description": "The EC2 Instance Type.",
        "allowedValues": [
          "internet-submit",
          "customer-submit"
        ]
      },
      "SxlRevision": {
        "type":"String",
        "description": "SXL Revision to apply",
        "default": "b",
        "allowedValues": [
          "a",
          "b"
        ]
      }
    },
    "mainSteps": [
      {
        "name": "chooseAutomation",
        "action": "aws:branch",
        "isEnd": "true",
        "inputs": {
          "Choices": [
            {
              "Variable": "{{SxlRevision}}",
              "StringEquals": "b",
              "NextStep": "updateSxlRevision"
            },
            {
              "Variable": "{{SxlRevision}}",
              "StringEquals": "a",
              "NextStep": "rollbackSxlRevision"
            }
          ]
        }
      },
      {
        "name": "updateSxlRevision",
        "action": "aws:executeAutomation",
        "maxAttempts": 3,
        "timeoutSeconds": 3600,
        "isEnd": "true",
        "onFailure": "Abort",
        "inputs": {
          "DocumentName": "${aws_ssm_document.sxl_instance_update_automation.name}",
          "RuntimeParameters": {
            "InstanceType": "{{InstanceType}}",
            "SxlCurrent": "a",
            "SxlUpdate": "b"
          }
        }
      },
      {
        "name": "rollbackSxlRevision",
        "action": "aws:executeAutomation",
        "maxAttempts": 3,
        "timeoutSeconds": 3600,
        "isEnd": "true",
        "onFailure": "Abort",
        "inputs": {
          "DocumentName": "${aws_ssm_document.sxl_instance_update_automation.name}",
          "RuntimeParameters": {
            "InstanceType": "{{InstanceType}}",
            "SxlCurrent": "b",
            "SxlUpdate": "a"
          }
        }
      }
    ]
  }
}

resource "aws_ssm_document" "postfix_sxl_update_automation" {
  name          = "postfix-sxl-update-automation"
  document_type = "Automation"

  content = jsonencode(local.postfix_sxl_update_automation_ssm_document)
}

# ----------------------------------------------------
# SSM Automation IAM Role and Policies
# ----------------------------------------------------

resource "aws_iam_role" "postfix_sxl_update_automation_role" {
  name = "postfix_sxl_update_automation_role"
  assume_role_policy = data.aws_iam_policy_document.postfix_sxl_update_automation_trust_policy.json
}

data "aws_iam_policy_document" "postfix_sxl_update_automation_trust_policy" {
  policy_id = "postfix_sxl_update_automation_trust_policy"

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

data "aws_iam_policy_document" "postfix_sxl_update_automation_policy" {
  policy_id = "postfix_sxl_update_automation_policy"

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
      "ec2:CreateTags",
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

resource "aws_iam_role_policy" "postfix_sxl_update_automation_policy" {
  name   = "postfix-sxl-update-automation-policy"
  role   = aws_iam_role.postfix_sxl_update_automation_role.id
  policy = data.aws_iam_policy_document.postfix_sxl_update_automation_policy.json
}
