# vim: autoindent expandtab shiftwidth=2 filetype=terraform
resource "aws_ssm_document" "terminate_asg_instance_automation" {
  name          = "terminate-asg-instance-automation"
  document_type = "Automation"

  content = <<DOC
  {
    "schemaVersion": "0.3",
    "assumeRole": "${aws_iam_role.terminate_asg_instance_automation_role.arn}",
    "description": "Terminate an EC2 instance in an AutoScaling Group",
    "parameters": {
      "InstanceId": {
        "type": "String",
        "description": "The EC2 Instance Id."
      },
      "ShouldDecrementDesiredCapacity": {
        "type": "Boolean",
        "default": false,
        "allowedValues": [
          true,
          false
        ],
        "description": "Indicates whether terminating the instance also decrements the size of the Auto Scaling group."
      }
    },
    "mainSteps":[
      {
        "name": "terminateInstanceInAutoScalingGroup",
        "action": "aws:executeAwsApi",
        "maxAttempts": 3,
        "timeoutSeconds": 60,
        "inputs": {
          "Service": "autoscaling",
          "Api": "TerminateInstanceInAutoScalingGroup",
          "InstanceId": "{{InstanceId}}",
          "ShouldDecrementDesiredCapacity": "{{ShouldDecrementDesiredCapacity}}"
        },
        "outputs": [
          {
            "Name": "StatusMessage",
            "Selector": "$.Activity.StatusMessage",
            "Type": "String"
          }
        ]
      }
    ]
  }
DOC
}

# ----------------------------------------------------
# SSM Automation IAM Role and Policies
# ----------------------------------------------------

resource "aws_iam_role" "terminate_asg_instance_automation_role" {
  name = "terminate_asg_instance_automation_role"
  assume_role_policy = data.aws_iam_policy_document.terminate_asg_instance_automation_trust_policy.json
}

data "aws_iam_policy_document" "terminate_asg_instance_automation_trust_policy" {
  policy_id = "terminate_asg_instance_automation_trust_policy"

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

data "aws_iam_policy_document" "terminate_asg_instance_automation_policy" {
  policy_id = "terminate_asg_instance_automation_policy"

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
    sid = "AutoScalingPermissions"
    effect = "Allow"
    actions = [
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
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
      "ssm:DescribeInstanceInformation",
      "ssm:GetAutomationExecution",
      "ssm:GetCommandInvocation",
      "ssm:GetConnectionStatus",
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

resource "aws_iam_role_policy" "terminate_asg_instance_automation_policy" {
  name   = "terminate-asg-instance-automation-policy"
  role   = aws_iam_role.terminate_asg_instance_automation_role.id
  policy = data.aws_iam_policy_document.terminate_asg_instance_automation_policy.json
}
