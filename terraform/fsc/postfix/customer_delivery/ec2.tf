locals {
  DEFAULT_AS_ALARM_SCALING_ENABLED      = false
  DEFAULT_AS_ALARM_SCALE_IN_THRESHOLD   = 10
  DEFAULT_AS_ALARM_SCALE_OUT_THRESHOLD  = 50
  DEFAULT_AS_MIN_SIZE                   = 1
  DEFAULT_AS_MAX_SIZE                   = 6
  DEFAULT_AS_MIN_SERVICE                = 1
  DEFAULT_AS_MAX_BATCH_SIZE             = 1
  DEFAULT_AS_CRON_SCALE_DOWN            = "0 1 * * 6"
  DEFAULT_AS_CRON_SCALE_UP              = "0 4 * * 1"
  DEFAULT_AS_CRON_SCALE_IN              = "00 02 * * 1-5"
  DEFAULT_AS_CRON_SCALE_OUT             = "30 14 * * 1-5"
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD  = 900
  DEFAULT_AS_POLICY_TARGET_VALUE        = 90
  DEFAULT_AS_ON_HOUR_DESIRED            = 2
  DEFAULT_AS_SCALE_IN_OUT_WEEKDAYS      = false
  DEFAULT_AS_SCALE_IN_ON_WEEKENDS       = false
  DEFAULT_INSTANCE_SIZE                 = "t2.small"
  DEFAULT_INSTANCE_COUNT                = 1
  DEFAULT_XGEMAIL_SIZE_DATA_GB          = 35
  DEFAULT_SXL_DBL                       = "uri.cal1.sophosxl.com"
  DEFAULT_SXL_RBL                       = "fur.cal1.sophosxl.com"

  AS_ALARM_SCALING_ENABLED_BY_ENVIRONMENT = {
    inf  = false
    dev  = false
    qa   = false
    prod = true
  }
  AS_ALARM_SCALE_IN_THRESHOLD_BY_ENVIRONMENT = {
    inf  = 10
    dev  = 10
    qa   = 10
    prod = 100
  }

  AS_ALARM_SCALE_OUT_THRESHOLD_BY_ENVIRONMENT = {
    inf  = 50
    dev  = 50
    qa   = 50
    prod = 500
  }
  AS_MIN_SIZE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 6
  }

  AS_MAX_SIZE_BY_ENVIRONMENT = {
    inf  = 6
    dev  = 6
    qa   = 6
    prod = 12
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

  AS_CRON_SCALE_DOWN_BY_ENVIRONMENT = {
    inf  = "0 1 * * 6"
    dev  = "0 1 * * 6"
    qa   = "0 1 * * 6"
    prod = "0 1 * * 6"
  }

  AS_CRON_SCALE_UP_BY_ENVIRONMENT = {
    inf  = "0 4 * * 1"
    dev  = "0 4 * * 1"
    qa   = "0 4 * * 1"
    prod = "0 4 * * 1"
  }

  AS_CRON_SCALE_IN_BY_ENVIRONMENT = {
    inf  = "00 02 * * 1-5"
    dev  = "00 02 * * 1-5"
    qa   = "00 02 * * 1-5"
    prod = "00 02 * * 1-5"
  }

  AS_CRON_SCALE_OUT_BY_ENVIRONMENT = {
    inf  = "30 14 * * 1-5"
    dev  = "30 14 * * 1-5"
    qa   = "30 14 * * 1-5"
    prod = "30 14 * * 1-5"
  }

  AS_HEALTH_CHECK_GRACE_PERIOD_BY_ENVIRONMENT = {
    inf  = 2400
    dev  = 2400
    qa   = 2400
    prod = 2400
  }

  AS_POLICY_TARGET_VALUE_BY_ENVIRONMENT = {
    inf  = 90
    dev  = 90
    qa   = 90
    prod = 65
  }

  AS_ON_HOUR_DESIRED_BY_ENVIRONMENT = {
    inf  = 2
    dev  = 2
    qa   = 2
    prod = 2
  }

  AS_SCALE_IN_OUT_WEEKDAYS_BY_ENVIRONMENT = {
    inf  = false
    dev  = false
    qa   = false
    prod = false
  }

  AS_SCALE_IN_ON_WEEKENDS_BY_ENVIRONMENT = {
    inf  = false
    dev  = false
    qa   = false
    prod = false
  }

  INSTANCE_SIZE_BY_ENVIRONMENT = {
    inf  = "t2.small"
    dev  = "c4.xlarge"
    qa   = "c4.xlarge"
    prod = "m5a.large"
  }

  XGEMAIL_SIZE_DATA_GB_BY_ENVIRONMENT = {
    inf  = 40
    dev  = 40
    qa   = 70
    prod = 300
  }

  SXL_DBL_BY_ENVIRONMENT = {
    inf  = "uri.cal1.sophosxl.com"
    dev  = "uri.cal1.sophosxl.com"
    qa   = "uri.cal1.sophosxl.com"
    prod = "uri.cal1.sophosxl.com"
  }

  SXL_DBL_BY_POP = {
    stn000cmh = "uri.cal1.sophosxl.com"
  }

  SXL_RBL_BY_ENVIRONMENT = {
    inf  = "fur.cal1.sophosxl.com"
    dev  = "fur.cal1.sophosxl.com"
    qa   = "fur.cal1.sophosxl.com"
    prod = "fur.cal1.sophosxl.com"
  }

  SXL_RBL_BY_POP = {
    stn000cmh = "fur.cal1.sophosxl.com"
  }

  alarm_scaling_enabled = lookup(
  local.AS_ALARM_SCALING_ENABLED_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_ALARM_SCALING_ENABLED
  )

  alarm_scale_in_threshold = lookup(
  local.AS_ALARM_SCALE_IN_THRESHOLD_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_ALARM_SCALE_IN_THRESHOLD
  )

  alarm_scale_out_threshold = lookup(
  local.AS_ALARM_SCALE_OUT_THRESHOLD_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_ALARM_SCALE_OUT_THRESHOLD
  )

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

  as_cron_scale_down = lookup(
  local.AS_CRON_SCALE_DOWN_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_CRON_SCALE_DOWN
  )

  as_cron_scale_up = lookup(
  local.AS_CRON_SCALE_UP_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_CRON_SCALE_UP
  )

  as_cron_scale_in = lookup(
  local.AS_CRON_SCALE_IN_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_CRON_SCALE_IN
  )

  as_cron_scale_out = lookup(
  local.AS_CRON_SCALE_OUT_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_CRON_SCALE_OUT
  )

  health_check_grace_period = lookup(
  local.AS_HEALTH_CHECK_GRACE_PERIOD_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD
  )

  as_policy_target_value = lookup(
  local.AS_POLICY_TARGET_VALUE_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_POLICY_TARGET_VALUE
  )

  as_on_hour_desired = lookup(
  local.AS_ON_HOUR_DESIRED_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_ON_HOUR_DESIRED
  )

  as_scale_in_out_weekdays = lookup(
  local.AS_SCALE_IN_OUT_WEEKDAYS_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_SCALE_IN_OUT_WEEKDAYS
  )

  as_scale_in_on_weekends = lookup(
  local.AS_SCALE_IN_ON_WEEKENDS_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_AS_SCALE_IN_ON_WEEKENDS
  )

  instance_size = lookup(
  local.INSTANCE_SIZE_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_INSTANCE_SIZE
  )

  xgemail_size_data_gb = lookup(
  local.XGEMAIL_SIZE_DATA_GB_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_XGEMAIL_SIZE_DATA_GB
  )

  sxl_dbl = lookup(
  local.SXL_DBL_BY_POP,
  local.input_param_account_name,
  lookup(
  local.SXL_DBL_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_SXL_DBL
  )
  )

  sxl_rbl = lookup(
  local.SXL_RBL_BY_POP,
  local.input_param_account_name,
  lookup(
  local.SXL_RBL_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_SXL_RBL
  )
  )
}

resource "aws_cloudformation_stack" "cloudformation_stack" {
  name = "customer-delivery"
  template_body = "${file("${path.module}/templates/as_customer_delivery_template.json")}"
  parameters = {
    AccountName                       = local.input_param_account_name
    AlarmScalingEnabled               = local.alarm_scaling_enabled
    AlarmScaleInThreshold             = local.alarm_scale_in_threshold
    AlarmScaleOutThreshold            = local.alarm_scale_out_threshold
    AlarmTopicArn                     = local.input_param_alarm_topic_arn
    AmiId                             = data.aws_ami.ami.id
    AutoScalingInstanceRoleArn        = local.input_param_autoscaling_role_arn
    AutoScalingMinSize                = local.as_min_size
    AutoScalingMaxSize                = local.as_max_size
    AutoScalingNotificationTopicARN   = local.input_param_lifecycle_topic_arn
    AvailabilityZones                 = local.input_param_availability_zones
    Branch                            = var.build_branch
    BuildTag                          = var.build_tag
    BuildUrl                          = var.build_url
    BundleVersion                     = local.ami_build
    DeployMaxBatchSize                = local.as_max_batch_size
    DeployMinInstancesInService       = local.as_min_service
    Environment                       = local.input_param_deployment_environment
    HealthCheckGracePeriod            = local.health_check_grace_period
    InstanceProfile                   = local.input_param_iam_instance_profile_arn
    InstanceType                      = local.instance_size
    LifecycleHookLaunching            = local.input_param_lifecycle_hook_launching
    LifecycleHookTerminating          = local.input_param_lifecycle_hook_terminating
    LoadBalancerName                  = aws_elb.elb.id
    MsgHistoryV2BucketName            = var.message_history_ms_bucket
    MsgHistoryV2DynamoDbTableName     = var.message_history_dynamodb_table_name
    MsgHistoryV2StreamName            = var.firehose_msg_history_v2_stream_name
    S3CookbookRepositoryURL           = "//${local.input_param_cloud_templates_bucket_name}/${var.build_branch}/cookbooks.tar.gz"
    ScaleInOnWeekends                 = local.as_scale_in_on_weekends
    ScaleInCron                       = local.as_cron_scale_down
    ScaleOutCron                      = local.as_cron_scale_up
    ScheduledAsOnHourDesiredCapacity  = local.as_on_hour_desired
    ScaleInAndOutOnWeekdays           = local.as_scale_in_out_weekdays
    ScaleInOnWeekdaysCron             = local.as_cron_scale_in
    ScaleOutOnWeekdaysCron            = local.as_cron_scale_out
    SecurityGroups                    = aws_security_group.security_group_ec2.id
    SpotPrice                         = "-1"
    StationVpcId                      = var.station_vpc_id
    StationVpcName                    = "station"
    Vpc                               = local.input_param_vpc_id
    VpcZoneIdentifiers                = join(",", local.input_param_public_subnet_ids)
    VpcName                           = "email"
    XgemailBucketName                 = var.customer_delivery_bucket
    XgemailMinSizeDataGB              = local.xgemail_size_data_gb
    XgemailMsgHistoryBucketName       = var.message_history_bucket
    XgemailMsgHistoryMsBucketName     = var.message_history_ms_bucket
    XgemailMsgHistoryQueueUrl         = var.message_history_sqs_queue
    XgemailMsgHistoryStatusQueueUrl   = var.message_history_status_sqs_queue
    XgemailMsgHistoryStatusSnsArn     = var.message_history_status_sns_topic
    XgemailPolicyBucketName           = var.policy_bucket
    XgemailSnsSqsQueue                = var.customer_delivery_sqs_queue_name
    XgemailSnsSqsQueueUrl             = var.customer_delivery_sqs_queue_url
    XgemailServiceType                = local.instance_type
    XgemailSxlDbl                     = local.sxl_dbl
    XgemailSxlRbl                     = local.sxl_rbl
  }
}
