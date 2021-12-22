data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "encryption_instances_cross_account_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [var.encryption_instances_instance_role_arn]
  }
}

resource "aws_iam_policy" "encryption_instances_cross_account_policy" {
  name_prefix = "EncryptionInstancesCrossAccountPolicy-"
  path        = "/"
  description = "Policy for Encryption Instances Cross Account Access"
  policy      = data.aws_iam_policy_document.encryption_instances_cross_account_policy.json

  tags = { Name = "EncryptionInstancesCrossAccountPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "outbound_submit_cross_account_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [var.outbound_submit_instance_role_arn]
  }
}

resource "aws_iam_policy" "outbound_submit_cross_account_policy" {
  name_prefix = "OutboundSubmitCrossAccountPolicy-"
  path        = "/"
  description = "Policy for Outbound Submit Cross Account Access"
  policy      = data.aws_iam_policy_document.outbound_submit_cross_account_policy.json

  tags = { Name = "OutboundSubmitCrossAccountPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "inbound_delivery_cross_account_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [var.inbound_delivery_instance_role_arn]
  }
}

resource "aws_iam_policy" "inbound_delivery_cross_account_policy" {
  name_prefix = "InboundDeliveryCrossAccountPolicy-"
  path        = "/"
  description = "Policy for Inbound Delivery Cross Account Access"
  policy      = data.aws_iam_policy_document.inbound_delivery_cross_account_policy.json

  tags = { Name = "InboundDeliveryCrossAccountPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "inbound_submit_cross_account_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [var.inbound_submit_instance_role_arn]
  }
}

resource "aws_iam_policy" "inbound_submit_cross_account_policy" {
  name_prefix = "InboundSubmitCrossAccountPolicy-"
  path        = "/"
  description = "Policy for Inbound Submit Cross Account Access"
  policy      = data.aws_iam_policy_document.inbound_submit_cross_account_policy.json

  tags = { Name = "InboundSubmitCrossAccountPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "outbound_delivery_cross_account_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [var.outbound_delivery_instance_role_arn]
  }
}

resource "aws_iam_policy" "outbound_delivery_cross_account_policy" {
  name_prefix = "OutboundDeliveryCrossAccountPolicy-"
  path        = "/"
  description = "Policy for Outbound Delivery Cross Account Access"
  policy      = data.aws_iam_policy_document.outbound_delivery_cross_account_policy.json

  tags = { Name = "OutboundDeliveryCrossAccountPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------
# Autoscaling
# ----------------------------------------------------

data "aws_iam_policy_document" "asg_policy" {
  policy_id = "asg_policy"

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLifecycleHooks",
      "autoscaling:RecordLifecycleActionHeartbeat",
      "autoscaling:UpdateAutoScalingGroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "asg_policy" {
  name_prefix = "AsgPolicy-"
  path        = "/"
  description = "Policy for Autoscaling Access"
  policy      = data.aws_iam_policy_document.asg_policy.json

  tags = { Name = "AsgPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------
# EC2
# ----------------------------------------------------

data "aws_iam_policy_document" "ec2_policy" {
  policy_id = "ec2_policy"

  statement {
    effect = "Allow"
    actions = [
      "ec2:AssociateAddress",
      "ec2:AttachVolume",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstances",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpcs",
      "ec2:DetachVolume",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifySnapshotAttribute"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_policy" {
  name_prefix = "Ec2Policy-"
  path        = "/"
  description = "Policy for EC2 Access"
  policy      = data.aws_iam_policy_document.ec2_policy.json

  tags = { Name = "Ec2Policy" }

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------
# SQS
# ----------------------------------------------------

data "aws_iam_policy_document" "sqs_policy" {
  policy_id = "sqs_policy"

  statement {
    effect = "Allow"
    actions = [
      "sqs:AddPermission",
      "sqs:ChangeMessageVisibility",
      "sqs:CreateQueue",
      "sqs:DeleteQueue",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ListQueues",
      "sqs:ListQueueTags",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:SetQueueAttributes",
    ]
    resources = ["arn:aws:sqs:${local.input_param_primary_region}:${local.input_param_account_id}:*"]
  }
}

resource "aws_iam_policy" "sqs_policy" {
  name_prefix = "SqsPolicy-"
  path        = "/"
  description = "Policy for managing/accessing SOA managed SQS queues"
  policy      = data.aws_iam_policy_document.sqs_policy.json

  tags = { Name = "SqsPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------
# SNS
# ----------------------------------------------------

data "aws_iam_policy_document" "sns_policy" {
  policy_id = "sns_policy"

  statement {
    effect = "Allow"
    actions = [
      "sns:ListSubscriptionsByTopic",
      "sns:ListTopics",
      "sns:Publish",
      "sns:Subscribe",
      "sns:Unsubscribe",
    ]
    resources = ["arn:aws:sns:${local.input_param_primary_region}:${local.input_param_account_id}:*"]
  }
}

resource "aws_iam_policy" "sns_policy" {
  name_prefix = "SnsPolicy-"
  path        = "/"
  description = "Policy for managing/accessing SOA managed SNS Topics"
  policy      = data.aws_iam_policy_document.sns_policy.json

  tags = { Name = "SnsPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------
# S3
# ----------------------------------------------------

data "aws_iam_policy_document" "s3_runtime_config_policy" {
  policy_id = "s3_runtime_config_policy"

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::cloud-*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:List*",
      "kms:ReEncrypt*",
      "kms:RevokeGrant",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetEncryptionConfiguration",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "s3_runtime_config_policy" {
  name_prefix = "S3RuntimeConfigPolicy-"
  path        = "/"
  description = "Policy for S3 config access"
  policy      = data.aws_iam_policy_document.s3_runtime_config_policy.json

  tags = { Name = "S3RuntimeConfigPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------
# CloudWatch
# ----------------------------------------------------

data "aws_iam_policy_document" "cloudwatch_put_metric_policy" {
  policy_id = "cloudwatch_put_metric_policy"

  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:putMetricData"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_put_metric_policy" {
  name_prefix = "CloudWatchPutMetricPolicy-"
  path        = "/"
  description = "Policy for CloudWatch Put Metric Policy"
  policy      = data.aws_iam_policy_document.cloudwatch_put_metric_policy.json

  tags = { Name = "CloudWatchPutMetricPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------
# SSM
# ----------------------------------------------------

resource "aws_iam_policy" "ssm_agent_policy" {
  name_prefix = "SsmAgentPolicy-"
  path        = "/"
  description = "Policy for SSM access"
  policy      = data.aws_iam_policy_document.ssm_agent_policy.json

  tags = { Name = "SsmAgentPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy" "ssm_managed_instance_core" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ssm_agent_policy" {
  source_json = data.aws_iam_policy.ssm_managed_instance_core.policy
}

data "aws_iam_policy" "firehose_writer_policy" {
  arn = local.input_param_firehose_writer_policy_arn
}

data "aws_iam_policy" "volume_tracker_simpledb_policy" {
  arn = local.input_param_volume_tracker_simpledb_policy_arn
}
