locals {
  eip_rotation_lambda_name = "eip_rotation"
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

resource "aws_lambda_function" "eip_rotation" {
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
      DEPLOYMENT_ENVIRONMENT = local.input_param_deployment_environment
      TYPE                   = "lambda"
    }
  }
  tags = {
    Name = local.eip_rotation_lambda_name
  }
}

resource "aws_lambda_permission" "eip_rotation_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eip_rotation.function_name
  principal     = "events.amazonaws.com"
  statement_id  = "AllowExecutionFromCloudWatch"
}