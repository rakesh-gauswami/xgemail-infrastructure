resource "aws_iam_instance_profile" "risky_delivery_instance_profile" {
  name = "RiskyDeliveryInstanceProfile"
  path = "/"
  role = aws_iam_role.risky_delivery_instance_role.name

  tags = {
    Name        = "RiskyDeliveryInstanceProfile"
    Application = "RiskyDelivery"
  }
}

resource "aws_iam_role" "risky_delivery_instance_role" {
  name_prefix        = "RiskyDeliveryInstanceRole-"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json


  tags = {
    Name = "RiskyDeliveryInstanceRole"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "risky_delivery_instance_role_cloudwatch_policy" {
  role       = aws_iam_role.risky_delivery_instance_role.id
  policy_arn = aws_iam_policy.cloudwatch_put_metric_policy.arn
}

resource "aws_iam_role_policy_attachment" "risky_delivery_instance_role_sqs_policy" {
  role       = aws_iam_role.risky_delivery_instance_role.id
  policy_arn = aws_iam_policy.sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "risky_delivery_instance_role_outbound_delivery_cross_account_policy" {
  role       = aws_iam_role.risky_delivery_instance_role.id
  policy_arn = aws_iam_policy.outbound_delivery_cross_account_policy.arn
}

resource "aws_iam_role_policy_attachment" "risky_delivery_instance_role_s3_runtime_config_policy" {
  role       = aws_iam_role.risky_delivery_instance_role.id
  policy_arn = aws_iam_policy.s3_runtime_config_policy.arn
}

resource "aws_iam_role_policy_attachment" "risky_delivery_instance_role_firehose_writer_policy" {
  role       = aws_iam_role.risky_delivery_instance_role.id
  policy_arn = data.aws_iam_policy.firehose_writer_policy.arn
}

resource "aws_iam_role_policy_attachment" "risky_delivery_instance_role_ssm_agent_policy" {
  role       = aws_iam_role.risky_delivery_instance_role.id
  policy_arn = aws_iam_policy.ssm_agent_policy.arn
}

resource "aws_iam_role_policy_attachment" "risky_delivery_instance_role_asg_policy" {
  role       = aws_iam_role.risky_delivery_instance_role.id
  policy_arn = aws_iam_policy.asg_policy.arn
}

resource "aws_iam_role_policy_attachment" "risky_delivery_instance_role_ec2_policy" {
  role       = aws_iam_role.risky_delivery_instance_role.id
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_role_policy_attachment" "risky_delivery_instance_role_sns_policy" {
  role       = aws_iam_role.risky_delivery_instance_role.id
  policy_arn = aws_iam_policy.sns_policy.arn
}

resource "aws_iam_role_policy_attachment" "risky_delivery_instance_role_secretsmanager_policy" {
  role       = aws_iam_role.risky_delivery_instance_role.id
  policy_arn = aws_iam_policy.secretsmanager_policy.arn
}
