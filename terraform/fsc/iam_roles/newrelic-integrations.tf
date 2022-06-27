locals {
  new_relic_role_name = "NewRelicInfrastructure-Integrations-${local.input_param_primary_region}"
}

data "aws_iam_policy_document" "new_relic_integrations_role_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::754728514883:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["${local.input_param_newrelic_account_id}"]
    }
  }
}

resource "aws_iam_role" "new_relic_integrations_role" {
  name = "${local.new_relic_role_name}"

  assume_role_policy = data.aws_iam_policy_document.new_relic_integrations_role_trust_policy.json

  tags = { Name = "${local.input_param_newrelic_account_id}" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "new_relic_read_only_policy" {
  role       = aws_iam_role.new_relic_integrations_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "new_relic_budget_policy" {
  statement {
    actions = ["budgets:ViewBudget"]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "new_relic_budget_policy" {
  name = "NewRelicBudget"
  role = aws_iam_role.new_relic_integrations_role.name

  policy = data.aws_iam_policy_document.new_relic_budget_policy.json
}
