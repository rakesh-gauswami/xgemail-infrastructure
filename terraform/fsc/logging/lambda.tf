locals {
  log_shipping_lambda_name = "log_shipping_lambda"
  firehose_transformation_lambda_name = "firehose_transformation_lambda"
}

resource "null_resource" "pip" {
  triggers = {
    build_number = timestamp()
  }
  provisioner "local-exec" {
    command = <<EOL
    pip3 install -r ${path.module}/${local.log_shipping_lambda_name}/src/requirements.txt -t ${path.module}/${local.log_shipping_lambda_name}/src;
    rm -rf ${path.module}/${local.log_shipping_lambda_name}/src/boto3*;
    rm -rf ${path.module}/${local.log_shipping_lambda_name}/src/botocore*;
    EOL
  }
}

data "archive_file" "log_shipping_lambda_zip" {
  type        = "zip"
  source_dir = "${path.module}/${local.log_shipping_lambda_name}/src/"
  output_path = "${path.module}/${local.log_shipping_lambda_name}.zip"
  depends_on = [
    null_resource.pip
  ]
}

data "archive_file" "firehose_transformation_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/${local.firehose_transformation_lambda_name}/src/${local.firehose_transformation_lambda_name}.py"
  output_path = "${path.module}/${local.firehose_transformation_lambda_name}.zip"
}

resource "aws_lambda_function" "log_shipping_lambda" {
  filename          = data.archive_file.log_shipping_lambda_zip.output_path
  function_name     = local.log_shipping_lambda_name
  role              = aws_iam_role.log_shipping_lambda_role.arn
  handler           = "${local.log_shipping_lambda_name}.${local.log_shipping_lambda_name}_handler"
  source_code_hash  = data.archive_file.log_shipping_lambda_zip.output_base64sha256
  runtime           = "python3.8"
  memory_size       = 256
  timeout           = 300
  environment {
    variables = {
      DEPLOYMENT_ENVIRONMENT = local.input_param_deployment_environment
      PREFIX                 = trimsuffix(local.logs_root, "/")
      TOKEN                  = local.input_secret_api_token
      TYPE                   = "lambda"
    }
  }
  tags = {
    Name = local.log_shipping_lambda_name
  }
}

resource "aws_lambda_function" "firehose_transformation_lambda" {
  filename          = data.archive_file.firehose_transformation_lambda_zip.output_path
  function_name     = "${local.firehose_transformation_lambda_name}"
  role              = aws_iam_role.firehose_transformation_lambda_role.arn
  handler           = "${local.firehose_transformation_lambda_name}.${local.firehose_transformation_lambda_name}_handler"
  source_code_hash  = data.archive_file.firehose_transformation_lambda_zip.output_base64sha256
  runtime           = "python3.7"
  memory_size       = 512
  timeout           = 300
  environment {
    variables = {
      DEPLOYMENT_ENVIRONMENT = local.input_param_deployment_environment
    }
  }
  tags = {
    Name = "${local.firehose_transformation_lambda_name}"
  }
}

resource "aws_lambda_permission" "log_shipping_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_shipping_lambda.function_name
  principal     = "s3.amazonaws.com"
  statement_id  = "AllowExecutionFromS3"
}

resource "aws_s3_bucket_notification" "log_bucket_notification" {
  bucket      = module.logs_bucket.bucket_name
  depends_on  = [
    aws_lambda_permission.log_shipping_lambda_permission
  ]

  lambda_function {
    lambda_function_arn = aws_lambda_function.log_shipping_lambda.arn
    events              = [
      "s3:ObjectCreated:*"
    ]
    filter_prefix       = local.logs_root
  }
}
