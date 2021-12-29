locals {
  # Configuration for elasticsearch across environments
  ami_owner_account = "843638552935"
  ami_type          = "xgemail"

  DEFAULT_AS_MIN_SIZE                  = 1
  DEFAULT_AS_MAX_SIZE                  = 1
  DEFAULT_AS_MIN_SERVICE               = 1
  DEFAULT_AS_MAX_BATCH_SIZE            = 1
  DEFAULT_AS_CRON_SCALE_IN             = "00 02 * * 1-5"
  DEFAULT_AS_CRON_SCALE_OUT            = "30 14 * * 1-5"
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD = 2400
  DEFAULT_AS_POLICY_TARGET_VALUE       = 90
  DEFAULT_AS_ON_HOUR_DESIRED           = 2
  DEFAULT_AS_SCALE_IN_OUT_WEEKDAYS     = false
  DEFAULT_INSTANCE_SIZE                = "t2.small"
  DEFAULT_INSTANCE_COUNT               = 1
  DEFAULT_VOLUME_SIZE_GIBS             = 35
  DEFAULT_SXL_DBL                      = "t2.small"
  DEFAULT_SXL_RBL                      = "t2.small"

  AS_MIN_SIZE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  AS_MAX_SIZE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 3
    prod = 3
  }

  AS_MIN_SERVICE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 3
    prod = 3
  }

  AS_MAX_BATCH_SIZE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 3
    prod = 3
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

  as_max_batch_size = lookup(
    local.AS_MAX_BATCH_SIZE_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_MAX_BATCH_SIZE
  )

  health_check_grace_period = lookup(
    local.AS_HEALTH_CHECK_GRACE_PERIOD_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD
  )

  instance_size = lookup(
    local.INSTANCE_SIZE_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_INSTANCE_SIZE
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
  name = "internet-delivery"
  template_body = file("${path.module}/templates/as-internet-delivery-template.json")
  parameters = {
    AlarmTopicArn                     = local.input_param_alarm_topic_arn
    AmiId                             = data.aws_ami.ami
    AutoScalingInstanceRoleArn        = local.input_param_autoscaling_instance_role_arn
    AutoScalingMinSize                = local.as_min_size
    AutoScalingMaxSize                = local.as_max_size
    AutoScalingNotificationTopicARN   = local.input_param_lifecycle_topic_arn
    AvailabilityZones                 = local.input_param_availability_zones
    Branch                            = var.build_branch
    BuildVersion                      = var.build_result_key
    BundleVersion                     = var.ami_branch
    DeployMaxBatchSize                = local.as_max_batch_size
    DeployMinInstancesInService       = local.as_min_service
    Environment                       = local.input_param_deployment_environment
    HealthCheckGracePeriod            = local.health_check_grace_period
    InstanceProfile                   = local.input_param_instance_profile_arn
    InstanceType                      = local.instance_size
    LifecycleHookTerminating          = local.input_param_lifecycle_hook_terminating
    LoadBalancerName                  = aws_elb.elb.id
    MsgHistoryV2BucketName            = var.msg_history_v2_bucket_name cross
    MsgHistoryV2StreamName            = var.firehose_msg_history_v2_stream_name cross
    MessageHistoryEventsTopicArn      = var.msg_history_events_sns_topic cross
    PolicyTargetValue                 = local.as_policy_target_value
    S3CookbookRepositoryURL           = "//${local.input_param_cloud_templates_bucket_name}/${var.build_branch}/xgemail-infrastructure/cookbooks.enc"
    ScaleInOnWeekends                 = local.weekend_scale_down
    ScaleInCron                       = local.cron_scale_down
    ScaleOutCron                      = local.cron_scale_up
    ScheduledASOnHourDesiredCapacity  = local.on_hour_desired
    ScaleInAndOutOnWeekdays           = local.scale_in_out_weekdays
    ScaleInOnWeekdaysCron             = local.cron_scale_in
    ScaleOutOnWeekdaysCron            = local.cron_scale_out
    SecurityGroups                    = [local.input_param_sg_base_id, aws_security_group.security_group_ec2]
    SpotPrice                         = var.spot_price
    StationVpcId                      = var.station_vpc_id cross
    StationVpcName                    = var.station_name cross
    Vpc                               = local.input_param_vpc_id
    VpcZoneIdentifiers                = [local.input_param_public_subnet_ids]
    VpcName                           = "email"
    XgemailBucketName                 = var.internet_delivery_bucket cross
    XgemailMinSizeDataGB              = local.volume_size_data_gb
    XgemailMsgHistoryBucketName       = var.msg_history_bucket cross
    XgemailMsgHistoryMsBucketName     = var.msg_history_ms_bucket cross
    XgemailMsgHistoryQueueUrl         = var.msg_history_sqs_queue cross
    XgemailPolicyArn                  = var.relay_control_sns_topic cross
    XgemailPolicyBucketName           = var.policy_bucket cross
    XgemailPolicyEfsFileSystemId      = local.input_param_policy_efs_mount_id
    XgemailQueueUrl                   = var.internet_delivery_sqs_queue cross
    XgemailScanEventsTopicArn         = var.scan_events_sns_topic cross
    XgemailServiceType                = local.instance_type
    XgemailSxlDbl                     = local.sxl_dbl
    XgemailSxlRbl                     = local.sxl_rbl
  }
}