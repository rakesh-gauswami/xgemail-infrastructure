locals {
  DEFAULT_AS_ALARM_SCALING_ENABLED          = false
  DEFAULT_AS_MIN_SIZE                       = 1
  DEFAULT_AS_MAX_SIZE                       = 6
  DEFAULT_AS_MIN_SERVICE                    = 1
  DEFAULT_AS_MAX_BATCH_SIZE                 = 1
  DEFAULT_AS_CRON_SCALE_DOWN                = "0 1 * * 6"
  DEFAULT_AS_CRON_SCALE_UP                  = "0 4 * * 1"
  DEFAULT_AS_CRON_SCALE_IN                  = "00 02 * * 1-5"
  DEFAULT_AS_CRON_SCALE_OUT                 = "30 14 * * 1-5"
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD      = 2400
  DEFAULT_AS_POLICY_TARGET_VALUE            = 90
  DEFAULT_AS_ON_HOUR_DESIRED                = 2
  DEFAULT_AS_SCALE_IN_OUT_WEEKDAYS          = false
  DEFAULT_AS_SCALE_IN_ON_WEEKENDS           = false
  DEFAULT_INSTANCE_SIZE                     = "t3.medium"
  DEFAULT_INSTANCE_COUNT                    = 1
  DEFAULT_NEWRELIC_ENABLED                  = false
  DEFAULT_VOLUME_SIZE_GIBS                  = 40
  DEFAULT_SXL_DBL                           = "uri.vir1.sophosxl.com"
  DEFAULT_SXL_RBL                           = "fur.vir1.sophosxl.com"

  AS_MIN_SIZE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 3
  }

  AS_MAX_SIZE_BY_ENVIRONMENT = {
    inf  = 3
    dev  = 3
    qa   = 3
    prod = 12
  }

  AS_MIN_SERVICE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 2
  }

  AS_MAX_BATCH_SIZE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 2
    prod = 2
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
    inf  = "t3a.medium"
    dev  = "t3.medium"
    qa   = "t3a.medium"
    prod = "m5a.large"
  }

  NEWRELIC_ENABLED_BY_ENVIRONMENT = {
    inf  = false
    dev  = false
    qa   = false
    prod = true
  }

  VOLUME_SIZE_GIBS_BY_ENVIRONMENT = {
    prod = 300
    inf  = 40
  }

  VOLUME_SIZE_GIBS_BY_POP = {
    stn000cmh = 40
  }

  SXL_DBL_BY_ENVIRONMENT = {
    inf  = "uri.vir1.sophosxl.com"
    dev  = "uri.vir1.sophosxl.com"
    qa   = "uri.vir1.sophosxl.com"
    prod = "uri.vir1.sophosxl.com"
  }

  SXL_DBL_BY_POP = {
    stn000cmh = "uri.vir1.sophosxl.com"
  }

  SXL_RBL_BY_ENVIRONMENT = {
    inf  = "fur.vir1.sophosxl.com"
    dev  = "fur.vir1.sophosxl.com"
    qa   = "fur.vir1.sophosxl.com"
    prod = "fur.vir1.sophosxl.com"
  }

  SXL_RBL_BY_POP = {
    stn000cmh = "fur.vir1.sophosxl.com"
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

  newrelic_enabled = lookup(
    local.NEWRELIC_ENABLED_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_NEWRELIC_ENABLED
  )

  volume_size_gibs = lookup(
    local.VOLUME_SIZE_GIBS_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_VOLUME_SIZE_GIBS
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
  name          = local.instance_type
  template_body = file("${path.module}/templates/as_customer_submit_template.json")
  parameters = {
    AccountName                           = local.input_param_account_name
    AlarmTopicArn                         = local.input_param_alarm_topic_arn
    AmiId                                 = var.ami_id
    AutoScalingInstanceRoleArn            = local.input_param_autoscaling_role_arn
    AutoScalingMinSize                    = local.as_min_size
    AutoScalingMaxSize                    = local.as_max_size
    AutoScalingNotificationTopicARN       = local.input_param_lifecycle_topic_arn
    AvailabilityZones                     = local.input_param_availability_zones
    Branch                                = var.build_branch
    BuildTag                              = var.build_tag
    BuildUrl                              = var.build_url
    BundleVersion                         = var.ami_build
    DeliveryDirectorBucketName            = var.delivery_director_bucket_name
    DeployMaxBatchSize                    = local.as_max_batch_size
    DeployMinInstancesInService           = local.as_min_service
    Environment                           = local.input_param_deployment_environment
    HealthCheckGracePeriod                = local.health_check_grace_period
    InstanceProfile                       = local.input_param_iam_instance_profile_name
    InstanceType                          = local.instance_size
    LifecycleHookTerminating              = local.input_param_lifecycle_hook_terminating
    LoadBalancerName                      = aws_elb.elb.id
    MsgHistoryV2BucketName                = var.message_history_ms_bucket
    MsgHistoryV2StreamName                = var.message_history_v2_stream_name
    MessageHistoryEventsTopicArn          = var.message_history_events_sns_topic
    NewRelicEnabled                       = local.newrelic_enabled
    PolicyTargetValue                     = local.as_policy_target_value
    S3CookbookRepositoryURL               = "//${local.input_param_cloud_templates_bucket_name}/${var.build_branch}/${var.build_number}/cookbooks.tar.gz"
    ScaleInOnWeekends                     = local.as_scale_in_on_weekends
    ScaleInCron                           = local.as_cron_scale_down
    ScaleOutCron                          = local.as_cron_scale_up
    ScheduledASOnHourDesiredCapacity      = local.as_on_hour_desired
    ScaleInAndOutOnWeekdays               = local.as_scale_in_out_weekdays
    ScaleInOnWeekdaysCron                 = local.as_cron_scale_in
    ScaleOutOnWeekdaysCron                = local.as_cron_scale_out
    SecurityGroups                        = aws_security_group.security_group_ec2.id
    SpotPrice                             = "-1"
    StationAccountRoleArn                 = var.station_account_role_arn
    StationVpcId                          = var.station_vpc_id
    StationVpcName                        = replace(var.station_name, "/-.*/", "")
    Vpc                                   = local.input_param_vpc_id
    VpcZoneIdentifiers                    = join(",", local.input_param_public_subnet_ids)
    VpcName                               = local.input_param_vpc_name
    XgemailBucketName                     = var.outbound_submit_bucket
    XgemailMinSizeDataGB                  = local.volume_size_gibs
    XgemailMsgHistoryBucketName           = var.message_history_bucket
    XgemailMsgHistoryMsBucketName         = var.message_history_ms_bucket
    XgemailMsgHistoryQueueUrl             = var.message_history_sqs_queue
    XgemailPolicyArn                      = var.relay_control_sns_topic
    XgemailPolicyBucketName               = var.policy_bucket
    XgemailPolicyEfsFileSystemId          = local.input_param_policy_efs_volume_id
    XgemailPostfixQueueEfsFileSystemId    = local.input_param_postfix_queue_efs_volume_id
    XgemailQueueUrl                       = var.customer_submit_sqs_queue
    XgemailScanEventsTopicArn             = var.scan_events_sns_topic
    XgemailServiceType                    = local.instance_type
    XgemailSxlDbl                         = local.sxl_dbl
    XgemailSxlRbl                         = local.sxl_rbl
  }
}
