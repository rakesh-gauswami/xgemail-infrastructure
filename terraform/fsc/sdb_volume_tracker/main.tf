#
# SimpleDB Domain Template for Sophos MSG FSC VPC
#
resource "aws_simpledb_domain" "volume_tracker" {
  name = "volume_tracker"

  provider = aws.parameters
}

data "aws_region" "volume_tracker" {

  provider = aws.parameters
}

data "aws_iam_policy_document" "volume_tracker_simpledb_policy" {
  policy_id = "volume_tracker_simpledb_policy"

  statement {
    actions   = [
      "sdb:ListDomains",
    ]

    sid = "SimpleDbList"

    effect    = "Allow"

    resources = [
      "*"
    ]

  }
  statement {
    sid = "SimpleDbVolumeTracker"
    actions   = [
      "sdb:BatchDeleteAttributes",
      "sdb:BatchPutAttributes",
      "sdb:CreateDomain",
      "sdb:DeleteAttributes",
      "sdb:DeleteDomain",
      "sdb:DomainMetadata",
      "sdb:GetAttributes",
      "sdb:PutAttributes",
      "sdb:Select",
    ]
    effect    = "Allow"
    resources = [
      "arn:aws:sdb:${data.aws_region.volume_tracker.name}:${local.input_param_account_id}:domain/${aws_simpledb_domain.volume_tracker.id}"
    ]
  }
}

resource "aws_iam_policy" "volume_tracker_simpledb_policy" {
  name_prefix = "VolumeTrackerSimpleDbPolicy-"
  path        = "/"
  description = "Policy for Volume Tracker SimpleDb"
  policy      = data.aws_iam_policy_document.volume_tracker_simpledb_policy.json
  lifecycle {
    create_before_destroy = true
  }
}
