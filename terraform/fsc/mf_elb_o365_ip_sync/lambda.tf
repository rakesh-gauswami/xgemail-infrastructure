locals {
  mf_elb_o365_ip_sync_lambda_name = "mf_elb_o365_ip_sync_lambda"
}

data "archive_file" "mf_elb_o365_ip_sync_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/${local.mf_elb_o365_ip_sync_lambda_name}/src/${local.mf_elb_o365_ip_sync_lambda_name}.py"
  output_path = "${path.module}/${local.mf_elb_o365_ip_sync_lambda_name}.zip"
}

resource "aws_lambda_function" "mf_elb_o365_ip_sync_lambda" {
  filename          = data.archive_file.mf_elb_o365_ip_sync_lambda_zip.output_path
  function_name     = local.mf_elb_o365_ip_sync_lambda_name
  role              = aws_iam_role.mf_elb_o365_ip_sync_lambda_execution_role.arn
  handler           = "${local.mf_elb_o365_ip_sync_lambda_name}.${local.mf_elb_o365_ip_sync_lambda_name}_handler"
  source_code_hash  = data.archive_file.mf_elb_o365_ip_sync_lambda_zip.output_base64sha256
  reserved_concurrent_executions = 1
  runtime           = "python3.8"
  memory_size       = 256
  timeout           = 300
  environment {
    variables = {
      ACCOUNT = local.input_param_account_type
      MFISSECURITYGROUP = local.input_param_mf_is_security_group
      MFOSSECURITYGROUP = local.input_param_mf_os_security_group
    }
  }
  tags = {
    Name = local.mf_elb_o365_ip_sync_lambda_name
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_scheduled_event" {
  statement_id  = "AllowExecutionFromCloudWatchScheduledEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mf_elb_o365_ip_sync_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.mf_elb_o365_ip_sync_scheduled_event_rule.arn
}