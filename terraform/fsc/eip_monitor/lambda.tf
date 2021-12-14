locals {
  eip_monitor_lambda_name = "eip_monitor_lambda"
}

resource "null_resource" "pip" {
  triggers = {
    build_number = timestamp()
  }
  provisioner "local-exec" {
    command = <<DOC
    pip3 install -r ${path.module}/${local.eip_monitor_lambda_name}/src/requirements.txt -t ${path.module}/${local.eip_monitor_lambda_name}/src;
    rm -rf ${path.module}/${local.eip_monitor_lambda_name}/src/boto3*;
    rm -rf ${path.module}/${local.eip_monitor_lambda_name}/src/botocore*;
    DOC
  }
}

data "archive_file" "eip_monitor_lambda_zip" {
  type        = "zip"
  source_dir = "${path.module}/${local.eip_monitor_lambda_name}/src/"
  output_path = "${path.module}/${local.eip_monitor_lambda_name}.zip"
  depends_on = [
    null_resource.pip
  ]
}

resource "aws_lambda_function" "eip_monitor_lambda" {
  filename          = data.archive_file.eip_monitor_lambda_zip.output_path
  function_name     = local.eip_monitor_lambda_name
  role              = aws_iam_role.eip_monitor_lambda_role.arn
  handler           = "${local.eip_monitor_lambda_name}.${local.eip_monitor_lambda_name}_handler"
  source_code_hash  = data.archive_file.eip_monitor_lambda_zip.output_base64sha256
  runtime           = "python3.8"
  memory_size       = 256
  timeout           = 300
  environment {
    variables = {
      TOKEN  = local.input_secret_api_token
    }
  }
  tags = {
    Name = local.eip_monitor_lambda_name
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_scheduled_event" {
  statement_id  = "AllowExecutionFromCloudWatchScheduledEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eip_monitor_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eip_monitor_scheduled_event_rule.arn
}
