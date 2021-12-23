# vim: autoindent expandtab shiftwidth=2 filetype=terraform

resource "aws_ssm_document" "multi_eip_rotation" {
  name          = "multi-eip-rotation"
  document_type = "Automation"
  content       = <<-DOC
  {
    "schemaVersion": "0.3",
    "assumeRole": "${aws_iam_role.multi_eip_rotation_ssm_automation_role.arn}",
    "description": "Rotate all EIPs on an EC2 instance in an AutoScaling Group",
    "parameters": {
      "InstanceId": {
        "type": "String",
        "description": "(Required) The instance-id for the instance.",
        "allowedPattern": "^i-[a-z0-9]{8,17}$"
      }
    },
    "mainSteps":[
      {
        "name": "multiEipRotation",
        "action": "aws:invokeLambdaFunction",
        "timeoutSeconds": 300,
        "maxAttempts": 3,
        "onFailure": "Abort",
        "inputs": {
          "InvocationType": "RequestResponse",
          "LogType": "Tail",
          "FunctionName": "${aws_lambda_function.multi_eip_rotation_lambda.function_name}",
          "Payload":"{"EC2InstanceId":"{{InstanceId}}"}"
        }
      }
    ],
    "outputs": [
      "multiEipRotation.StatusCode",
      "multiEipRotation.FunctionError",
      "multiEipRotation.LogResult"
    ]
  }

  DOC
}
