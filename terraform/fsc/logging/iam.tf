# Firehose Role
data "aws_iam_policy_document" "firehose_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = [
        "firehose.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name_prefix = local.stream_prefix
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role_policy.json
}

data "aws_iam_policy_document" "firehose_lambda_policy" {
  statement {
    sid = "FirehoseLambdaPermissions"
    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration",
    ]
    effect    = "Allow"
    resources = [
      "${aws_lambda_function.firehose_transformation_lambda.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "firehose_lambda_policy" {
  name   = "firehose-lambda-policy"
  role   = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose_lambda_policy.json
}

data "aws_iam_policy_document" "firehose_cloudwatch_policy" {
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
      "arn:aws:logs:${local.input_param_primary_region}:*:log-group:${aws_cloudwatch_log_group.log_group.name}:*"
    ]
  }
}

resource "aws_iam_role_policy" "firehose_cloudwatch_policy" {
  name   = "firehose-cloudwatch-policy"
  role   = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose_cloudwatch_policy.json
}

data "aws_iam_policy_document" "firehose_logs_bucket_policy" {
  statement {
    sid = "FirehoseLogsBucket"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    effect    = "Allow"
    resources = [
      module.logs_bucket.bucket_arn
    ]
  }
  statement {
    sid = "FirehoseLogsBucketObjects"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetObject",
      "s3:PutObject"
    ]
    effect    = "Allow"
    resources = [
      "${module.logs_bucket.bucket_arn}/*"
    ]
  }
  statement {
    sid = "FirehoseLogsBucketKmsKey"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    effect    = "Allow"
    resources = [
      module.logs_bucket.bucket_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "firehose_logs_bucket_policy" {
  name   = "firehose-logs-bucket-policy"
  role   = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose_logs_bucket_policy.json
}

## Permissions needed for any resource to be able to push data to stream
data "aws_iam_policy_document" "firehose_writer_policy" {
  statement {
    sid = "FirehoseDescribeDeliveryStream"
    actions   = [
      "firehose:DescribeDeliveryStream"
    ]
    effect    = "Allow"
    resources = [
      "*"
    ]
  }
  statement {
    sid = "FirehosePutRecords"
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]
    effect    = "Allow"
    resources = [
      aws_kinesis_firehose_delivery_stream.log_shipping_firehose_stream.arn
    ]
  }
}

resource "aws_iam_policy" "firehose_writer_policy" {
  name_prefix = "LoggingFirehosePolicy-"
  path        = "/"
  description = "Policy for Writing Logs to Firehose"
  policy      = data.aws_iam_policy_document.firehose_writer_policy.json
  lifecycle {
    create_before_destroy = true
  }
}

# Log Shipping Lambda Permissions
resource "aws_iam_role" "log_shipping_lambda_role" {
  name_prefix        = "log-shipping-lambda-"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "logs_bucket_read_policy" {
  statement {
    sid = "LogsBucketReadPermissions"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [
      module.logs_bucket.bucket_arn
    ]
  }
  statement {
    sid = "LogsBucketObjectsReadPermissions"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    effect    = "Allow"
    resources = [
      "${module.logs_bucket.bucket_arn}/*"
    ]
  }
  statement {
    actions = [
      "kms:Decrypt",
    ]
    effect    = "Allow"
    resources = [
      module.logs_bucket.bucket_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "logs_bucket_read_lambda_policy" {
  name = "log-shipping-lambda-logs-bucket-read-policy"
  role = aws_iam_role.log_shipping_lambda_role.id
  policy = data.aws_iam_policy_document.logs_bucket_read_policy.json
}

data "aws_iam_policy_document" "log_shipping_lambda_cloudwatch_policy" {
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
      "arn:aws:logs:${local.input_param_primary_region}:*:log-group:/aws/lambda/${local.log_shipping_lambda_name}:*"
    ]
  }
}

resource "aws_iam_role_policy" "log_shipping_lambda_cloudwatch_policy" {
  name   = "log-shipping-lambda-cloudwatch-policy"
  role   = aws_iam_role.log_shipping_lambda_role.id
  policy = data.aws_iam_policy_document.log_shipping_lambda_cloudwatch_policy.json
}

# Firehose Transformation Lambda Permissions
resource "aws_iam_role" "firehose_transformation_lambda_role" {
  name_prefix        = "firehose-transformation-lambda-"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "firehose_transformation_lambda_cloudwatch_policy" {
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
      "arn:aws:logs:${local.input_param_primary_region}:*:log-group:/aws/lambda/${local.firehose_transformation_lambda_name}:*"
    ]
  }
}

resource "aws_iam_role_policy" "firehose_transformation_lambda_cloudwatch_policy" {
  name   = "firehose-transformation-lambda-cloudwatch-policy"
  role   = aws_iam_role.firehose_transformation_lambda_role.id
  policy = data.aws_iam_policy_document.firehose_transformation_lambda_cloudwatch_policy.json
}

# Cloudwatch Logs to Firehose
resource "aws_iam_role" "cloudwatch_logs_firehose_role" {
  name               = "cloudwatch-logs-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_logs_assume_role_policy.json
}

data "aws_iam_policy_document" "cloudwatch_logs_assume_role_policy" {
  statement {
    actions   = [
      "sts:AssumeRole"
    ]
    effect    = "Allow"
    principals {
      type        = "Service"
      identifiers = [
        "logs.${local.input_param_primary_region}.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_logs_firehose_policy" {
  statement {
    sid = "CloudWatchLogsFirehose"
    actions   = [
      "firehose:*"
    ]
    effect    = "Allow"
    resources = [
      aws_kinesis_firehose_delivery_stream.log_shipping_firehose_stream.arn
    ]
  }
}

resource "aws_iam_role_policy" "cloudwatch_logs_firehose_policy" {
  name   = "cloudwatch-logs-to-firehose-policy"
  role   = aws_iam_role.cloudwatch_logs_firehose_role.name
  policy = data.aws_iam_policy_document.cloudwatch_logs_firehose_policy.json
}
