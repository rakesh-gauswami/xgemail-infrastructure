locals {
  eip_rotation_lambda_name = "eip_rotation_lambda"
}

resource "null_resource" "pip" {
  triggers = {
    build_number = timestamp()
  }
  provisioner "local-exec" {
    command = <<EOL
    pip3 install -t ${path.module}/${local.eip_rotation_lambda_name}/src;
    rm -rf ${path.module}/${local.eip_rotation_lambda_name}/src/boto3*;
    rm -rf ${path.module}/${local.eip_rotation_lambda_name}/src/botocore*;
    EOL
  }
}

data "archive_file" "eip_rotation_zip" {
  type        = "zip"
  source_dir  = "${path.module}/${local.eip_rotation_lambda_name}/src/"
  output_path = "${path.module}/${local.eip_rotation_lambda_name}.zip"
  depends_on  = [
    null_resource.pip
  ]
}

resource "aws_lambda_function" "eip_rotation_lambda" {
  filename          = data.archive_file.eip_rotation_zip.output_path
  function_name     = local.eip_rotation_lambda_name
  role              = aws_iam_role.eip_rotation_lambda_execution_role.arn
  handler           = "${local.eip_rotation_lambda_name}.${local.eip_rotation_lambda_name}_handler"
  source_code_hash  = data.archive_file.eip_rotation_zip.output_base64sha256
  runtime           = "python3.8"
  memory_size       = 256
  timeout           = 300
  environment {
    variables = {
      ACCOUNT                = local.input_param_account_type
      AWS_REGION             = local.input_param_primary_region
      SSM_POSTFIX_SERVICE    = local.input_param_ssm_postfix_service
      SSM_UPDATE_HOSTNAME    = local.input_param_ssm_update_hostname
      TYPE                   = "lambda"
    }
  }
  tags = {
    Name = local.eip_rotation_lambda_name
  }
}

resource "aws_lambda_permission" "eip_rotation_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eip_rotation_lambda.function_name
  principal     = "events.amazonaws.com"
  statement_id  = "AllowExecutionFromCloudWatch"
}

resource "aws_lambda_permission" "allow_cloudwatch_lifecycle_event" {
  statement_id  = "AllowExecutionFromCloudWatchLifecycleEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eip_rotation_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eip_rotation_event_rule.arn
}