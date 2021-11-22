# vim: autoindent expandtab shiftwidth=2 filetype=terraform
resource "aws_ssm_document" "tag_instance_automation" {
  name          = "tag-instance-automation"
  document_type = "Automation"

  content = <<DOC
  {
    "schemaVersion": "0.3",
    "assumeRole": "{{assumeRole}}",
    "description": "Update a Tag on an EC2 instance in an AutoScaling Group",
    "parameters": {
      "assumeRole": {
        "type": "String",
        "description": "Role under which to run the automation",
        "default": ""
      },
      "InstanceId": {
        "type": "String",
        "description": "(Required) The instance-id for the instance.",
        "allowedPattern": "^i-[a-z0-9]{8,17}$"
      },
      "Tag": {
        "type": "String",
        "description": "The Tag."
      },
      "Value": {
        "type": "String",
        "description": "The Tag value."
      }
    },
    "mainSteps":[
      {
        "name": "tagInstance",
        "action": "aws:createTags",
        "maxAttempts": 3,
        "onFailure": "Abort",
        "inputs": {
          "ResourceType":"EC2",
          "ResourceIds":[
            "{{InstanceId}}"
          ],
          "Tags": [
            {
              "Key": "{{Tag}}",
              "Value": "{{Value}}"
            }
          ]
        },
        "isCritical": "true",
        "isEnd": "true"
      }
    ]
  }
DOC
}
