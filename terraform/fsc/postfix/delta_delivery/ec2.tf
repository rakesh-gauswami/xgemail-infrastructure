locals {
  DEFAULT_AS_ALARM_SCALING_ENABLED          = false
  DEFAULT_AS_ALARM_SCALE_OUT_THRESHOLD      = 50
  DEFAULT_AS_MIN_SIZE                       = 0
  DEFAULT_AS_MAX_SIZE                       = 6
  DEFAULT_AS_MIN_SERVICE                    = 1
  DEFAULT_AS_MAX_BATCH_SIZE                 = 1
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD      = 2400
  DEFAULT_AS_DYNAMIC_CPU_TARGET_VALUE       = 90
  DEFAULT_AS_PREDICTIVE_CPU_TARGET_VALUE    = 90
  DEFAULT_EIP_COUNT                         = 1
  DEFAULT_INSTANCE_SIZE                     = "t3.medium"
  DEFAULT_NEWRELIC_ENABLED                  = false
  DEFAULT_XGEMAIL_SIZE_DATA_GB              = 10
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
    prod = 500
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
    prod = 4
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
    inf  = 2400
    dev  = 2400
    qa   = 2400
    prod = 2400
  }

  AS_DYNAMIC_CPU_TARGET_VALUE_BY_ENVIRONMENT = {
    inf  = 90
    dev  = 90
    qa   = 90
    prod = 75
  }

  AS_PREDICTIVE_CPU_TARGET_VALUE_BY_ENVIRONMENT = {
    inf  = 90
    dev  = 90
    qa   = 90
    prod = 75
  }

  EIP_COUNT_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  INSTANCE_SIZE_BY_ENVIRONMENT = {
    inf  = "t3.medium"
    dev  = "t3.medium"
    qa   = "t3.medium"
    prod = "m6i.large"
  }

  NEWRELIC_ENABLED_BY_ENVIRONMENT = {
    inf  = false
    dev  = false
    qa   = false
    prod = true
  }

  XGEMAIL_SIZE_DATA_GB_BY_ENVIRONMENT = {
    inf  = 10
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

  eip_count = lookup(
    local.EIP_COUNT_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_EIP_COUNT
  )

  health_check_grace_period = lookup(
    local.AS_HEALTH_CHECK_GRACE_PERIOD_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD
  )

  as_dynamic_cpu_target_value = lookup(
    local.AS_DYNAMIC_CPU_TARGET_VALUE_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_DYNAMIC_CPU_TARGET_VALUE
  )

  as_predictive_cpu_target_value = lookup(
    local.AS_PREDICTIVE_CPU_TARGET_VALUE_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_PREDICTIVE_CPU_TARGET_VALUE
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
  template_body = file("${path.module}/templates/as_delta_delivery_template.json")
  parameters = {
    AccountName                         = local.input_param_account_name
    AlarmScalingEnabled                 = local.alarm_scaling_enabled
    AlarmScaleOutThreshold              = local.alarm_scale_out_threshold
    AlarmTopicArn                       = local.input_param_alarm_topic_arn
    AmiId                               = var.ami_id
    AutoScalingInstanceRoleArn          = local.input_param_autoscaling_role_arn
    AutoScalingMinSize                  = local.as_min_size
    AutoScalingMaxSize                  = local.as_max_size
    AutoScalingNotificationTopicARN     = local.input_param_lifecycle_topic_arn
    AvailabilityZones                   = local.input_param_availability_zones
    Branch                              = var.build_branch
    BuildTag                            = var.build_tag
    BuildUrl                            = var.build_url
    BundleVersion                       = var.ami_build
    DeployMaxBatchSize                  = local.as_max_batch_size
    DeployMinInstancesInService         = local.as_min_service
    DynamicCpuTargetValue               = local.as_dynamic_cpu_target_value
    EipCount                            = local.eip_count
    Environment                         = local.input_param_deployment_environment
    HealthCheckGracePeriod              = local.health_check_grace_period
    InstanceProfile                     = local.input_param_iam_instance_profile_name
    InstanceType                        = local.instance_size
    LifecycleHookLaunching              = local.input_param_lifecycle_hook_launching
    LifecycleHookTerminating            = local.input_param_lifecycle_hook_terminating
    LoadBalancerName                    = aws_elb.elb.id
    MsgHistoryV2BucketName              = var.message_history_bucket
    MsgHistoryV2DynamoDbTableName       = var.message_history_dynamodb_table_name
    MsgHistoryV2StreamName              = var.message_history_v2_stream_name
    NewRelicEnabled                     = local.newrelic_enabled
    ParentAccountName                   = local.input_param_parent_account_name
    PredictiveCpuTargetValue            = local.as_predictive_cpu_target_value
    S3CookbookRepositoryURL             = "//${local.input_param_cloud_templates_bucket_name}/${var.build_branch}/${local.instance_type}/${var.build_number}/cookbooks.tar.gz"
    SecurityGroups                      = aws_security_group.security_group_ec2.id
    SpotPrice                           = "-1"
    StationAccountRoleArn               = var.station_account_role_arn
    StationVpcId                        = var.station_vpc_id
    StationVpcName                      = replace(var.station_name, "/-.*/", "")
    Vpc                                 = local.input_param_vpc_id
    VpcName                             = local.input_param_vpc_name
    VpcZoneIdentifiers                  = join(",", local.input_param_public_subnet_ids)
    XgemailBucketName                   = var.outbound_submit_bucket
    XgemailMinSizeDataGB                = local.xgemail_size_data_gb
    XgemailMsgHistoryStatusSnsArn       = var.msg_history_status_sns_topic
    XgemailNotifierQueueUrl             = var.notifier_request_sqs_queue
    XgemailPolicyBucketName             = var.policy_bucket
    XgemailPostfixQueueEfsFileSystemId  = local.input_param_postfix_queue_efs_volume_id
    XgemailSnsSqsQueue                  = var.delta_delivery_sqs_queue_name
    XgemailSnsSqsQueueUrl               = var.delta_delivery_sqs_queue_url
    XgemailServiceType                  = local.instance_type
    XgemailSxlDbl                       = local.sxl_dbl
    XgemailSxlRbl                       = local.sxl_rbl
  }
}
