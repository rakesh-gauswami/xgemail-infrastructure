locals {
  multi_eip_rotation_lambda_name = "multi_eip_rotation_lambda"
}

resource "null_resource" "pip" {
  triggers = {
    build_number = timestamp()
  }
  provisioner "local-exec" {
    command = <<EOL
    pip3 install -r ${path.module}/${local.multi_eip_rotation_lambda_name}/src/requirements.txt -t ${path.module}/${local.multi_eip_rotation_lambda_name}/src;
    rm -rf ${path.module}/${local.multi_eip_rotation_lambda_name}/src/boto3*;
    rm -rf ${path.module}/${local.multi_eip_rotation_lambda_name}/src/botocore*;
    EOL
  }
}

data "archive_file" "multi_eip_rotation_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/${local.multi_eip_rotation_lambda_name}/src/${local.multi_eip_rotation_lambda_name}.py"
  output_path = "${path.module}/${local.multi_eip_rotation_lambda_name}.zip"
}

resource "aws_lambda_function" "multi_eip_rotation_lambda" {
  filename          = data.archive_file.multi_eip_rotation_lambda_zip.output_path
  function_name     = local.multi_eip_rotation_lambda_name
  role              = aws_iam_role.multi_eip_rotation_lambda_execution_role.arn
  handler           = "${local.multi_eip_rotation_lambda_name}.${local.multi_eip_rotation_lambda_name}_handler"
  source_code_hash  = data.archive_file.multi_eip_rotation_lambda_zip.output_base64sha256
  runtime           = "python3.8"
  memory_size       = 256
  timeout           = 300
  environment {
    variables = {
      DEPLOYMENT_ENVIRONMENT = local.input_param_deployment_environment
    }
  }
  tags = {
    Name = local.multi_eip_rotation_lambda_name
  }
}
