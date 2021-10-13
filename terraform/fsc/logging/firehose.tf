locals {
  stream_prefix = "log-shipping-firehose-stream-"
  stream_name   = "${local.stream_prefix}${local.input_param_primary_region}-${local.input_param_account_type}"
}

resource "aws_kinesis_firehose_delivery_stream" "log_shipping_firehose_stream" {
  name        = local.stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn          = aws_iam_role.firehose_role.arn
    bucket_arn        = module.logs_bucket.bucket_arn
    kms_key_arn       = module.logs_bucket.bucket_kms_key_arn
    prefix            = local.logs_root
    buffer_interval   = var.stream_buffer_interval
    buffer_size       = var.stream_buffer_size

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.log_group.name
      log_stream_name = aws_cloudwatch_log_stream.log_stream.name
    }

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.firehose_transformation_lambda.arn}:$LATEST"
        }
      }
    }
  }

  tags = {
    Name = local.stream_name
  }
}

