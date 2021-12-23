# vim: autoindent expandtab shiftwidth=2 filetype=terraform

resource "aws_ssm_document" "eip_rotation" {
  name          = "eip-rotation"
  document_type = "Automation"

  content = <<-DOC
  {
    "schemaVersion": "0.3",
    "assumeRole": "${aws_iam_role.eip_rotation_role.arn}",
    "description": "Rotate EIP on an EC2 instance in an AutoScaling Group",
    "parameters": {
      "InstanceId": {
        "description": "(Required) The instance-id for the instance.",
        "type": "String",
        "allowedPattern": "^i-[a-z0-9]{8,17}$"
      },
      "Eip": {
        "default": "",
        "description": "(Optional) The Eip to attach to the instance.",
        "type": "String"
      }
    },
    "mainSteps": [
      {
        "name": "eipRotation",
        "action": "aws:invokeLambdaFunction",
        "timeoutSeconds": 300,
        "maxAttempts": 3,
        "onFailure": "Abort",
        "inputs": {
          "InvocationType": "RequestResponse",
          "LogType": "Tail",
          "FunctionName":"${aws_lambda_function.eip_rotation_lambda}",
          "Payload":"{"EC2InstanceId":"{{InstanceId}}", "Eip":"{{Eip}}"}"
          ]
        },
        "outputs": [
          "eipRotation.StatusCode",
          "eipRotation.FunctionError",
          "eipRotation.LogResult"
         ]
      }

  DOC
}
