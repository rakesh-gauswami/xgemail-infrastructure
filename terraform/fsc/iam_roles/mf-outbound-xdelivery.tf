resource "aws_iam_instance_profile" "mf_outbound_xdelivery_instance_profile" {
  name = "MfOutboundXdeliveryInstanceProfile"
  path = "/"
  role = aws_iam_role.mf_outbound_xdelivery_instance_role.name

  tags = {
    Name        = "MfOutboundXdeliveryInstanceProfile"
    Application = "MfOutboundXdelivery"
  }
}

resource "aws_iam_role" "mf_outbound_xdelivery_instance_role" {
  name_prefix        = "MfOutboundXdeliveryInstanceRole-"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json


  tags = {
    Name = "MfOutboundXdeliveryInstanceRole"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "mf_outbound_xdelivery_instance_role_sqs_policy" {
  role       = aws_iam_role.mf_outbound_xdelivery_instance_role.id
  policy_arn = aws_iam_policy.sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "mf_outbound_xdelivery_instance_role_outbound_delivery_cross_account_policy" {
  role       = aws_iam_role.mf_outbound_xdelivery_instance_role.id
  policy_arn = aws_iam_policy.outbound_delivery_cross_account_policy.arn
}

resource "aws_iam_role_policy_attachment" "mf_outbound_xdelivery_instance_role_s3_runtime_config_policy" {
  role       = aws_iam_role.mf_outbound_xdelivery_instance_role.id
  policy_arn = aws_iam_policy.s3_runtime_config_policy.arn
}

resource "aws_iam_role_policy_attachment" "mf_outbound_xdelivery_instance_role_firehose_writer_policy" {
  role       = aws_iam_role.mf_outbound_xdelivery_instance_role.id
  policy_arn = data.aws_iam_policy.firehose_writer_policy.arn
}

resource "aws_iam_role_policy_attachment" "mf_outbound_xdelivery_instance_role_ssm_agent_policy" {
  role       = aws_iam_role.mf_outbound_xdelivery_instance_role.id
  policy_arn = aws_iam_policy.ssm_agent_policy.arn
}

resource "aws_iam_role_policy_attachment" "mf_outbound_xdelivery_instance_role_asg_policy" {
  role       = aws_iam_role.mf_outbound_xdelivery_instance_role.id
  policy_arn = aws_iam_policy.asg_policy.arn
}

resource "aws_iam_role_policy_attachment" "mf_outbound_xdelivery_instance_role_ec2_policy" {
  role       = aws_iam_role.mf_outbound_xdelivery_instance_role.id
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_role_policy_attachment" "mf_outbound_xdelivery_instance_role_sns_policy" {
  role       = aws_iam_role.mf_outbound_xdelivery_instance_role.id
  policy_arn = aws_iam_policy.sns_policy.arn
}

resource "aws_iam_role_policy_attachment" "mf_outbound_xdelivery_instance_role_volume_tracker_simpledb_policy" {
  role       = aws_iam_role.mf_outbound_xdelivery_instance_role.id
  policy_arn = data.aws_iam_policy.volume_tracker_simpledb_policy.arn
}

resource "aws_iam_role_policy_attachment" "mf_outbound_xdelivery_instance_role_secretsmanager_policy" {
  role       = aws_iam_role.mf_outbound_xdelivery_instance_role.id
  policy_arn = aws_iam_policy.secretsmanager_policy.arn
}
