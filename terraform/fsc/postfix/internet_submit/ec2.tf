locals {
  DEFAULT_AS_ALARM_SCALING_ENABLED          = false
  DEFAULT_AS_ALARM_SCALE_OUT_THRESHOLD      = 500
  DEFAULT_AS_MIN_SIZE                       = 1
  DEFAULT_AS_MAX_SIZE                       = 3
  DEFAULT_AS_MIN_SERVICE                    = 1
  DEFAULT_AS_MAX_BATCH_SIZE                 = 1
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD      = 1800
  DEFAULT_AS_POLICY_TARGET_VALUE            = 85
  DEFAULT_AS_ON_HOUR_DESIRED                = 2
  DEFAULT_INSTANCE_SIZE                     = "t3.medium"
  DEFAULT_INSTANCE_COUNT                    = 1
  DEFAULT_NEWRELIC_ENABLED                  = false
  DEFAULT_XGEMAIL_SIZE_DATA_GB              = 35
  DEFAULT_SXL_DBL                           = "uri.vir1.sophosxl.com"
  DEFAULT_SXL_RBL                           = "fur.vir1.sophosxl.com"

  AS_ALARM_SCALING_ENABLED_BY_ENVIRONMENT = {
    inf  = false
    dev  = false
    qa   = false
    prod = true
  }

  AS_ALARM_SCALE_OUT_THRESHOLD_BY_ENVIRONMENT = {
    inf  = 50
    dev  = 50
    qa   = 50
    prod = 30000
  }

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

  AS_HEALTH_CHECK_GRACE_PERIOD_BY_ENVIRONMENT = {
    inf  = 1800
    dev  = 1800
    qa   = 1800
    prod = 1800
  }

  AS_POLICY_TARGET_VALUE_BY_ENVIRONMENT = {
    inf  = 85
    dev  = 85
    qa   = 85
    prod = 55
  }

  AS_ON_HOUR_DESIRED_BY_ENVIRONMENT = {
    inf  = 2
    dev  = 2
    qa   = 2
    prod = 2
  }

  INSTANCE_SIZE_BY_ENVIRONMENT = {
    inf  = "t3a.medium"
    dev  = "t3.medium"
    qa   = "t3a.medium"
    prod = "m6a.large"
  }

  INSTANCE_SIZE_BY_POP = {
    eml100bom = "m6a.large"
    eml100gru = "m6a.large"
    eml100hnd = "m6a.large"
    eml100syd = "m6a.large"
    eml100yul = "m6i.large"
  }
  instance_size = lookup(
    local.INSTANCE_SIZE_BY_POP,
    local.input_param_account_name,
    lookup(
      local.INSTANCE_SIZE_BY_ENVIRONMENT,
      local.input_param_deployment_environment,
      local.DEFAULT_INSTANCE_SIZE
    )
  )

  NEWRELIC_ENABLED_BY_ENVIRONMENT = {
    inf  = false
    dev  = false
    qa   = false
    prod = true
  }

  XGEMAIL_SIZE_DATA_GB_BY_ENVIRONMENT = {
    inf  = 40
    dev  = 40
    qa   = 70
    prod = 100
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

  alarm_scaling_enabled = lookup(
    local.AS_ALARM_SCALING_ENABLED_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_ALARM_SCALING_ENABLED
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
  name          = local.instance_type
  template_body = file("${path.module}/templates/as_internet_submit_template.json")
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
    DeployMaxBatchSize                    = local.as_max_batch_size
    DeployMinInstancesInService           = local.as_min_service
    Environment                           = local.input_param_deployment_environment
    HealthCheckGracePeriod                = local.health_check_grace_period
    InstanceProfile                       = local.input_param_iam_instance_profile_arn
    InstanceType                          = local.instance_size
    JilterHeloTelemetryStreamName         = var.jilter_helo_telemetry_stream_name
    LifecycleHookTerminating              = local.input_param_lifecycle_hook_terminating
    LoadBalancerName                      = aws_elb.elb.id
    MsgHistoryV2BucketName                = var.message_history_ms_bucket
    MsgHistoryV2StreamName                = var.message_history_v2_stream_name
    MessageHistoryEventsTopicArn          = var.message_history_events_sns_topic
    NewRelicEnabled                       = local.newrelic_enabled
    ParentAccountName                     = local.input_param_parent_account_name
    PolicyTargetValue                     = local.as_policy_target_value
    S3CookbookRepositoryURL               = "//${local.input_param_cloud_templates_bucket_name}/${var.build_branch}/${var.build_number}/cookbooks.tar.gz"
    ScheduledAsOnHourDesiredCapacity      = local.as_on_hour_desired
    SecurityGroups                        = aws_security_group.security_group_ec2.id
    SpotPrice                             = "-1"
    StationAccountRoleArn                 = var.station_account_role_arn
    StationVpcId                          = var.station_vpc_id
    StationVpcName                        = "station"
    Vpc                                   = local.input_param_vpc_id
    VpcZoneIdentifiers                    = join(",", local.input_param_public_subnet_ids)
    VpcName                               = "email"
    XgemailBucketName                     = var.internet_submit_bucket
    XgemailMinSizeDataGB                  = local.xgemail_size_data_gb
    XgemailMsgHistoryBucketName           = var.message_history_bucket
    XgemailMsgHistoryMsBucketName         = var.message_history_ms_bucket
    XgemailMsgHistoryQueueUrl             = var.message_history_sqs_queue
    XgemailPolicyArn                      = var.relay_control_sns_topic
    XgemailPolicyBucketName               = var.policy_bucket
    XgemailPolicyEfsFileSystemId          = local.input_param_policy_efs_volume_id
    XgemailPostfixQueueEfsFileSystemId    = local.input_param_postfix_queue_efs_volume_id
    XgemailQueueUrl                       = var.internet_submit_sqs_queue_name
    XgemailScanEventsTopicArn             = var.scan_events_sns_topic
    XgemailServiceType                    = local.instance_type
    XgemailSxlDbl                         = local.sxl_dbl
    XgemailSxlRbl                         = local.sxl_rbl
  }
}