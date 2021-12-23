locals {
  multi_eip_rotation_lambda_name = "multi_eip_rotation_lambda"
}

data "archive_file" "multi_eip_rotation_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/${local.multi_eip_rotation_lambda_name}/src/${local.multi_eip_rotation_lambda_name}.py"
  output_path = "${path.module}/${local.multi_eip_rotation_lambda_name}.zip"
}

resource "aws_lambda_function" "multi_eip_rotation_lambda" {
  filename         = data.archive_file.multi_eip_rotation_lambda_zip.output_path
  function_name    = local.multi_eip_rotation_lambda_name
  role             = aws_iam_role.multi_eip_rotation_lambda_execution_role.arn
  handler          = "${local.multi_eip_rotation_lambda_name}.${local.multi_eip_rotation_lambda_name}_handler"
  source_code_hash = data.archive_file.multi_eip_rotation_lambda_zip.output_base64sha256
  runtime          = "python3.8"
  memory_size      = 256
  timeout          = 300
  environment {
    variables = {
      SSM_POSTFIX_SERVICE = local.input_param_ssm_postfix_service
    }
  }
  tags = {
    Name = local.multi_eip_rotation_lambda_name
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_scheduled_event" {
  statement_id  = "AllowExecutionFromCloudWatchScheduledEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.multi_eip_rotation_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.multi_eip_rotation_scheduled_event_rule.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_lifecycle_event" {
  statement_id  = "AllowExecutionFromCloudWatchLifecycleEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.multi_eip_rotation_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.multi_eip_lifecycle_event_rule.arn
}
