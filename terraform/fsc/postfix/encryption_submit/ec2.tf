locals {
  DEFAULT_AS_ALARM_SCALING_ENABLED          = false
  DEFAULT_AS_MIN_SIZE                       = 1
  DEFAULT_AS_MAX_SIZE                       = 6
  DEFAULT_AS_MIN_SERVICE                    = 1
  DEFAULT_AS_MAX_BATCH_SIZE                 = 1
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD      = 2400
  DEFAULT_AS_DYNAMIC_CPU_TARGET_VALUE       = 90
  DEFAULT_AS_PREDICTIVE_CPU_TARGET_VALUE    = 90
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

  INSTANCE_SIZE_BY_ENVIRONMENT = {
    inf  = "t3a.medium"
    dev  = "t3.medium"
    qa   = "t3a.medium"
    prod = "m6a.large"
  }

  INSTANCE_SIZE_BY_POP = {
    eml100bom = "m6a.large"
    eml100gru = "m6i.large"
    eml100hnd = "m6a.large"
    eml100syd = "m6a.large"
    eml100yul = "m6i.large"
  }

  NEWRELIC_ENABLED_BY_ENVIRONMENT = {
    inf  = false
    dev  = false
    qa   = false
    prod = true
  }

  VOLUME_SIZE_GIBS_BY_ENVIRONMENT = {
    prod = 100
    inf  = 30
  }

  VOLUME_SIZE_GIBS_BY_POP = {
    stn000cmh = 40
  }

  SXL_DBL_BY_ENVIRONMENT = {
    inf  = "uri.vir1.sophosxl.com"
    dev  = "uri.vir1.sophosxl.com"
    qa   = "uri.ire1.sophosxl.com"
    prod = "uri.vir1.sophosxl.com"
  }

  SXL_DBL_BY_POP = {
    eml000cmh = "uri.vir1.sophosxl.com"
    eml100bom = "uri.ire1.sophosxl.com"
    eml100gru = "uri.vir1.sophosxl.com"
    eml100hnd = "uri.jap1.sophosxl.com"
    eml100syd = "uri.aus1.sophosxl.com"
    eml100yul = "uri.vir1.sophosxl.com"
  }

  SXL_RBL_BY_ENVIRONMENT = {
    inf  = "fur.vir1.sophosxl.com"
    dev  = "fur.vir1.sophosxl.com"
    qa   = "fur.ire1.sophosxl.com"
    prod = "fur.vir1.sophosxl.com"
  }

  SXL_RBL_BY_POP = {
    eml000cmh = "fur.vir1.sophosxl.com"
    eml100bom = "fur.ire1.sophosxl.com"
    eml100gru = "fur.vir1.sophosxl.com"
    eml100hnd = "fur.jap1.sophosxl.com"
    eml100syd = "fur.aus1.sophosxl.com"
    eml100yul = "fur.vir1.sophosxl.com"
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
    local.INSTANCE_SIZE_BY_POP,
    local.input_param_account_name,
    lookup(
      local.INSTANCE_SIZE_BY_ENVIRONMENT,
      local.input_param_deployment_environment,
      local.DEFAULT_INSTANCE_SIZE
    )
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
  template_body = file("${path.module}/templates/as_encryption_submit_template.json")
  parameters = {
    AccountName                         = local.input_param_account_name
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
    Environment                         = local.input_param_deployment_environment
    HealthCheckGracePeriod              = local.health_check_grace_period
    InstanceProfile                     = local.input_param_iam_instance_profile_name
    InstanceType                        = local.instance_size
    LifecycleHookTerminating            = local.input_param_lifecycle_hook_terminating
    LoadBalancerName                    = aws_elb.elb.id
    MsgHistoryV2BucketName              = var.message_history_ms_bucket
    MsgHistoryV2DynamoDbTableName       = var.msg_history_v2_dynamodb
    MsgHistoryV2StreamName              = var.message_history_v2_stream_name
    MessageHistoryEventsTopicArn        = var.message_history_events_sns_topic
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
    VpcZoneIdentifiers                  = join(",", local.input_param_public_subnet_ids)
    VpcName                             = local.input_param_vpc_name
    XgemailBucketName                   = var.inbound_submit_bucket
    XgemailCustomerSubmitBucketName     = var.outbound_submit_bucket
    XgemailCustomerSubmitQueueUrl       = var.customer_submit_sqs_queue
    XgemailMinSizeDataGB                = local.volume_size_gibs
    XgemailMsgHistoryBucketName         = var.message_history_bucket
    XgemailMsgHistoryMsBucketName       = var.message_history_ms_bucket
    XgemailMsgHistoryQueueUrl           = var.message_history_sqs_queue
    XgemailPolicyBucketName             = var.policy_bucket
    XgemailPostfixQueueEfsFileSystemId  = local.input_param_postfix_queue_efs_volume_id
    XgemailQueueUrl                     = var.internet_submit_sqs_queue
    XgemailServiceType                  = local.instance_type
    XgemailSxlDbl                       = local.sxl_dbl
    XgemailSxlRbl                       = local.sxl_rbl
  }
}
