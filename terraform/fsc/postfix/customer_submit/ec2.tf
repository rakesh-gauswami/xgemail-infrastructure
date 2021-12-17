locals {
  # Configuration for elasticsearch across environments
  ami_owner_account = "843638552935"
  ami_type          = "xgemail"


  DEFAULT_AS_MIN_SIZE                   = 1
  DEFAULT_AS_MAX_SIZE                   = 1
  DEFAULT_AS_MIN_SERVICE                = 1
  DEFAULT_AS_MAX_BATCH_SIZE             = 1
  DEFAULT_AS_CRON_SCALE_IN              = "00 02 * * 1-5"
  DEFAULT_AS_CRON_SCALE_OUT             = "30 14 * * 1-5"
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD  = 2400
  DEFAULT_AS_POLICY_TARGET_VALUE        = 90
  DEFAULT_AS_ON_HOUR_DESIRED            = 2
  DEFAULT_AS_SCALE_IN_OUT_WEEKDAYS      = false
  DEFAULT_INSTANCE_SIZE                 = "t2.small"
  DEFAULT_INSTANCE_COUNT                = 1
  DEFAULT_VOLUME_SIZE_GIBS              = 35
  DEFAULT_SXL_DBL                       = "t2.small"
  DEFAULT_SXL_RBL                       = "t2.small"



  AS_MIN_SIZE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  AS_MAX_SIZE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  AS_MIN_SERVICE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 3
    prod = 3
  }

  AS_MAX_BATCH_SIZE_BY_ENVIRONMENT = {
    inf  = "t2.small"
    prod = "t2.small"
  }

  AS_CRON_SCALE_IN_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 2
    prod = 3
  }

  AS_CRON_SCALE_OUT_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 2
    prod = 3
  }

  AS_HEALTH_CHECK_GRACE_PERIOD_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 2
    prod = 3
  }

  AS_POLICY_TARGET_VALUE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  AS_ON_HOUR_DESIRED_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  AS_SCALE_IN_OUT_WEEKDAYS_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  INSTANCE_SIZE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  INSTANCE_COUNT_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  VOLUME_SIZES_GIBS_BY_ENVIRONMENT = {
    prod = 300
    inf  = 10
  }

  VOLUME_SIZES_GIBS_BY_POP = {
    # This is a most granular setting, if you need adjustments in particular PoP set it here

    stn000cmh = 10

  }

  SXL_DBL_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  SXL_DBL_BY_POP = {
    stn000cmh = 10
  }

  SXL_RBL_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  SXL_RBL_BY_POP = {
    stn000cmh = 10
  }

  as_min_size = lookup(
    local.AS_MIN_SIZE_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_MIN_SIZE
  )

  as_max_size = lookup(
    local.AS_MAX_SIZE_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_MAX_SIZE
  )

  as_min_service = lookup(
    local.AS_MIN_SERVICE_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_MIN_SERVICE
  )



}

data "aws_ami" "ami" {
  most_recent      = true
  owners           = [local.ami_owner_account]

  filter {
    name   = "name"
    values = ["hmr-core-${var.build_branch}-${local.ami_type}-*"]
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
  name: "customer-submit"
    template_body = "${file("${path.module}/templates/as-customer-submit-template.json")}"
    parameters = {
      AesDecryptionKey                  =                     "{{NO}}"
      AlarmTopicArn                     = local.input_param_alarm_topic_arn
      AmiId                             = data.aws_ami.ami
      AutoScalingInstanceRoleArn        = local.input_param_autoscaling_instance_role_arn
      AutoScalingMinSize                = local.as_min_size
      AutoScalingMaxSize                = local.as_max_size
      AutoScalingNotificationTopicARN   = local.input_param_lifecycle_topic_arn
      AvailabilityZones                 = local.input_param_availability_zones
      Branch                            = var.build.branch
      BuildVersion                      =                         "{{build.result_key}}"
      BundleVersion                     =                        "{{ami_build}}"
      DeployMaxBatchSize                =                   "{{aws.asg.cs.as_max_batch_size}}"
      DeployMinInstancesInService       = local.as_min_service
      Environment                       = local.input_param_deployment_environment
      HealthCheckGracePeriod            = local.health_check_grace_period
      InstanceProfile                   = local.input_param_instance_profile_arn
      InstanceType                      = local
      KeyName                           =                              "{{NO}}"
      LifecycleHookTerminating          = local.input_param_lifecycle_hook_terminating
      LoadBalancerName                  = aws_elb.elb.id
      MsgHistoryV2BucketName            =           cross    "{{s3.msg_history_v2_bucket_name}}"
      MsgHistoryV2StreamName            =           cross    "{{kinesis.firehose.msg_history_v2_stream_name}}"
      MessageHistoryEventsTopicArn      =        cross "{{sns.arn_prefix}}{{sns.msg_history_events_sns_topic}}"
      PolicyTargetValue                 =                    "{{aws.asg.cs.policy_target_value}}"
      S3CookbookRepositoryURL           =              "//cloud-{{account.name}}-templates/{{build.branch}}/xgemail-infrastructure/cookbooks.enc"
      ScaleInOnWeekends                 =                    "{{weekend_scale_down}}"
      ScaleInCron                       =                          "{{cron_scale_down}}"
      ScaleOutCron                      =                         "{{cron_scale_up}}"
      ScheduledASOnHourDesiredCapacity  =     "{{aws.asg.cs.on_hour_desired}}"
      ScaleInAndOutOnWeekdays           =              "{{aws.asg.cs.scale_in_out_weekdays}}"
      ScaleInOnWeekdaysCron             =                "{{aws.asg.cs.cron_scale_in}}"
      ScaleOutOnWeekdaysCron            =               "{{aws.asg.cs.cron_scale_out}}"
      SecurityGroups                    = [local.input_param_sg_base_id, aws_security_group.security_group_ec2]
      SpotPrice                         =                            "{{spot_price}}"
      StationVpcId                      =                  cross       "{{cloud_station_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_station_vpc].stack_outputs.Vpc}}"
      StationVpcName                    =                cross       "{{vpc.cloud_station.name}}"
      Vpc                               =                                  "{{cloud_email_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_email_vpc].stack_outputs.Vpc}}"
      VpcZoneIdentifiers                = [local.input_param_public_subnet_ids]
      VpcName                           = "email"
      XgemailBucketName                 =              cross      "{{s3.customer_submit_bucket}}"
      XgemailMinSizeDataGB              =                 "{{xgemail_size_data_gb}}"
      XgemailMsgHistoryBucketName       =      cross    "{{s3.msg_history_bucket}}"
      XgemailMsgHistoryMsBucketName     =     cross   "{{s3.msg_history_ms_bucket}}"
      XgemailMsgHistoryQueueUrl         =     cross       "{{sqs.url_prefix}}{{sqs.msg_history_sqs_queue}}"
      XgemailPolicyArn                  =      cross               "{{sns.arn_prefix}}{{sns.relay_control_sns_topic}}"
      XgemailPolicyBucketName           =      cross        "{{s3.policy_bucket}}"
      XgemailPolicyEfsFileSystemId      =         "{{cloud_email_efs_output.ansible_facts.cloudformation[stack.efs.policy_efs_volume].stack_outputs.FileSystemId}}"
      XgemailQueueUrl                   =       cross               "{{sqs.url_prefix}}{{sqs.customer_submit_sqs_queue}}"
      XgemailScanEventsTopicArn         =      cross      "{{sns.arn_prefix}}{{sns.scan_events_sns_topic}}"
      XgemailServiceType                = local.instance_type
      XgemailSxlDbl                     = local.sxl_dbl
      XgemailSxlRbl                     = local.sxl_rbl
    }
}
