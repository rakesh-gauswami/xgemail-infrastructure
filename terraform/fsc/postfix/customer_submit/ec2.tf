locals {
  # Configuration for elasticsearch across environments
  ami_owner_account = "843638552935"
  ami_type          = "xgemail"
  #branch            = var.branch


  DEFAULT_AS_MIN_SIZE      = 1
  DEFAULT_AS_MAX_SIZE      = 1
  DEFAULT_AS_MIN_SERVICE      = 1
  DEFAULT_AS_MAX_BATCH_SIZE      = 1
  DEFAULT_AS_CRON_SCALE_IN      = 1
  DEFAULT_AS_CRON_SCALE_OUT      = 1
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD      = 1
  DEFAULT_AS_LIFECYCLE_HOOK_TERMINATING      = 1
  DEFAULT_AS_POLICY_TARGET_VALUE      = 1
  DEFAULT_AS_ON_HOUR_DESIRED      = 1
  DEFAULT_AS_SCALE_IN_OUT_WEEKDAYS      = 1
  DEFAULT_AS_MIN_SIZE      = 1
  DEFAULT_INSTANCE_TYPE    = "t2.medium.elasticsearch"
  DEFAULT_INSTANCE_COUNT   = length(local.input_param_private_subnet_ids)
  DEFAULT_VOLUME_SIZE_GIBS      = 35


    alarm_scaling_enabled:                                      "false"
      as_min_size:                                                "1"
      as_max_size:                                                "3"
      as_min_service:                                             "1"
      as_max_batch_size:                                          "1"
      cron_scale_in:                                              "00 02 * * 1-5"
      cron_scale_out:                                             "30 14 * * 1-5"
      health_check_grace_period:                                  "2400"
      instance_size:                                              "t2.small"
      lifecycle_hook_terminating:                                 "{{vpc.cloud_email.name}}-customer-submit-Terminating-LifeCycleHook"
      policy_target_value:                                        "90"
      on_hour_desired:                                            "2"
      scale_in_out_weekdays:                                      "false"

  INSTANCE_TYPES_BY_ENVIRONMENT = {
    prod = "m4.xlarge.elasticsearch"
  }

  INSTANCE_COUNTS_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 2
    prod = 3
  }

  VOLUME_SIZES_GIBS_BY_ENVIRONMENT = {
    prod = 300
    inf  = 10
  }

  VOLUME_SIZES_GIBS_BY_POP = {
    # This is a most granular setting, if you need adjustments in particular PoP set it here

    stn000cmh = 10

  }

  ZONE_AWARENESS_BY_ENVIRONMENT = {
    inf  = false
    dev  = false
    qa   = true
    prod = true
  }

  AS_MIN_SIZE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = length(local.input_param_private_subnet_ids)
  }

}

data "aws_ami" "ami" {
  most_recent      = true
  owners           = [local.ami_owner_account]

  filter {
    name   = "name"
    values = ["hmr-core-${var.branch}-${local.ami_type}-*"]
  }

  filter {
    name   = "is-public"
    values = ["no"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "tag:ami_type"
    values = [local.ami_type]
  }
}

resource "aws_cloudformation_stack" "cloudformation_stack" {
  name: "{{stack.ec2.asg.cd}}"
    region:  "{{account.region}}"
    disable_rollback: no
    template_body: "{{template.ec2.asg.as_customer_delivery_template}}"
    parameters = {
      AesDecryptionKey =                      "{{aes_decryption_key}}"
      AlarmScaleInEnabled =                   "{{aws.asg.cd.alarm_scale_in_enabled}}"
      AlarmScaleOutEnabled =                  "{{aws.asg.cd.alarm_scale_out_enabled}}"
      AlarmScaleInThreshold =                 "{{aws.asg.cd.alarm_scale_in_threshold}}"
      AlarmScaleOutThreshold =                "{{aws.asg.cd.alarm_scale_out_threshold}}"
      AlarmTopicArn =                         "{{sns.arn_prefix}}{{sns.alarm_sns_topic}}"
      AmiId =                                 "{{ami_parent_id}}"
      AutoScalingInstanceRoleArn =            "{{cloud_email_iam_output.ansible_facts.cloudformation[stack.iam.role.cloud_email_roles].stack_outputs.AutoScalingInstanceRoleArn}}"
      AutoScalingMinSize =                    "{{aws.asg.cd.as_min_size}}"
      AutoScalingMaxSize =                    "{{aws.asg.cd.as_max_size}}"
      AutoScalingNotificationTopicARN =       "{{sns.arn_prefix}}{{sns.lifecycle_sqs_sns}}"
      AvailabilityZones =                     "{{cloud_email_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_email_vpc].stack_outputs.AvailabilityZones}}"
      Branch =                                "{{build.branch}}"
      BuildVersion =                          "{{build.result_key}}"
      BundleVersion =                         "{{ami_build}}"
      DeployMaxBatchSize =                    "{{aws.asg.cd.as_max_batch_size}}"
      DeployMinInstancesInService =           "{{aws.asg.cd.as_min_service}}"
      Environment =                           "{{account.name}}"
      HealthCheckGracePeriod =                "{{aws.asg.cd.health_check_grace_period}}"
      InstanceProfile =                       "{{cloud_email_iam_output.ansible_facts.cloudformation[stack.iam.role.cloud_email_roles].stack_outputs.XgemailCustomerDeliveryInstanceProfile}}"
      InstanceType =                          "{{aws.asg.cd.instance_size}}"
      KeyName =                               "private-{{account.region}}"
      LifecycleHookTerminating =              "{{aws.asg.cd.lifecycle_hook_terminating}}"
      LoadBalancerName =                      "{{elb_stack_output.stack_outputs.LoadBalancerId}}"
      MsgHistoryV2BucketName =                "{{s3.msg_history_v2_bucket_name}}"
      MsgHistoryV2DynamoDbTableName =         "{{dynamodb.msg_history_v2_dynamodb}}"
      MsgHistoryV2StreamName =                "{{kinesis.firehose.msg_history_v2_stream_name}}"
      S3CookbookRepositoryURL =               "//cloud-{{account.name}}-templates/{{build.branch}}/xgemail-infrastructure/cookbooks.enc"
      ScaleInOnWeekends =                     "{{weekend_scale_down}}"
      ScaleInCron =                           "{{cron_scale_down}}"
      ScaleOutCron =                          "{{cron_scale_up}}"
      ScheduledAsOnHourDesiredCapacity =      "{{aws.asg.cd.on_hour_desired}}"
      ScaleInAndOutOnWeekdays =               "{{aws.asg.cd.scale_in_out_weekdays}}"
      ScaleInOnWeekdaysCron =                 "{{aws.asg.cd.cron_scale_in}}"
      ScaleOutOnWeekdaysCron =                "{{aws.asg.cd.cron_scale_out}}"
      SecurityGroups =                        "{{cloud_email_sg_output.ansible_facts.cloudformation[stack.ec2.sg.cloud_email_security_groups].stack_outputs.XgemailCustomerDeliverySecurityGroup}},{{cloud_email_sg_output.ansible_facts.cloudformation[stack.ec2.sg.cloud_email_security_groups].stack_outputs.SecurityGroupBase}}"
      SpotPrice =                             "{{spot_price}}"
      StationVpcId =                          "{{cloud_station_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_station_vpc].stack_outputs.Vpc}}"
      StationVpcName =                        "{{vpc.cloud_station.name}}"
      Vpc =                                   "{{cloud_email_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_email_vpc].stack_outputs.Vpc}}"
      VpcZoneIdentifiers =                    "{{cloud_email_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_email_vpc].stack_outputs.PrivateSubnetDefaultA}},{{cloud_email_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_email_vpc].stack_outputs.PrivateSubnetDefaultB}},{{cloud_email_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_email_vpc].stack_outputs.PrivateSubnetDefaultC}}"
      VpcName =                               "{{vpc.cloud_email.name}}"
      XgemailBucketName =                     "{{s3.internet_submit_bucket}}"
      XgemailMinSizeDataGB =                  "{{xgemail_size_data_gb}}"
      XgemailMsgHistoryBucketName =           "{{s3.msg_history_bucket}}"
      XgemailMsgHistoryMsBucketName =         "{{s3.msg_history_ms_bucket}}"
      XgemailMsgHistoryQueueUrl =             "{{sqs.url_prefix}}{{sqs.msg_history_sqs_queue}}"
      XgemailMsgHistoryStatusQueueUrl =       "{{sqs.url_prefix}}{{sqs.msg_history_status_sqs_queue_sns_listener}}"
      XgemailMsgHistoryStatusSnsArn =         "{{sns.arn_prefix}}{{sns.msg_history_status_sns_topic}}"
      XgemailPolicyBucketName =               "{{s3.policy_bucket}}"
      XgemailSnsSqsQueue =                    "{{sqs.customer_delivery_sqs_queue_sns_listener}}"
      XgemailSnsSqsQueueUrl =                 "{{sqs.url_prefix}}{{sqs.customer_delivery_sqs_queue_sns_listener}}"
      XgemailServiceType =                    "customer-delivery"
      XgemailSxlDbl =                         "{{xgemail_sxl_dbl}}"
      XgemailSxlRbl =                         ""
    }
}
