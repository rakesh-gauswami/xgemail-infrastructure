locals {
  DEFAULT_AS_ALARM_SCALING_ENABLED     = false
  DEFAULT_AS_MIN_SIZE                  = 1
  DEFAULT_AS_MAX_SIZE                  = 6
  DEFAULT_AS_MIN_SERVICE               = 1
  DEFAULT_AS_MAX_BATCH_SIZE            = 1
  DEFAULT_AS_CRON_SCALE_DOWN           = "0 1 * * 6"
  DEFAULT_AS_CRON_SCALE_UP             = "0 4 * * 1"
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD = 2400
  DEFAULT_AS_POLICY_TARGET_VALUE       = 90
  DEFAULT_AS_SCALE_IN_ON_WEEKENDS      = false
  DEFAULT_INSTANCE_SIZE                = "t2.small"
  DEFAULT_INSTANCE_COUNT               = 1
  DEFAULT_VOLUME_SIZE_GIBS             = 40
  DEFAULT_SXL_DBL                      = "uri.cal1.sophosxl.com"
  DEFAULT_SXL_RBL                      = "fur.cal1.sophosxl.com"

  AS_MIN_SIZE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 1
    prod = 1
  }

  AS_MAX_SIZE_BY_ENVIRONMENT = {
    inf  = 6
    dev  = 6
    qa   = 6
    prod = 6
  }

  AS_MIN_SERVICE_BY_ENVIRONMENT = {
    inf  = 1
    dev  = 1
    qa   = 3
    prod = 3
  }

  AS_MAX_BATCH_SIZE_BY_ENVIRONMENT = {
    inf = 1
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
    prod = "m5.2xlarge"
  }

  VOLUME_SIZE_GIBS_BY_ENVIRONMENT = {
    prod = 100
    inf  = 30
  }

  VOLUME_SIZE_GIBS_BY_POP = {
    # This is a most granular setting, if you need adjustments in particular PoP set it here

    stn000cmh = 40

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
  template_body = file("${path.module}/templates/as_encryption_delivery_template.json")
  parameters = {
    AccountName                     = local.input_param_account_name
    AlarmTopicArn                   = local.input_param_alarm_topic_arn
    AmiId                           = data.aws_ami.ami.id
    AutoScalingInstanceRoleArn      = local.input_param_autoscaling_role_arn
    AutoScalingMinSize              = local.as_min_size
    AutoScalingMaxSize              = local.as_max_size
    AutoScalingNotificationTopicARN = local.input_param_lifecycle_topic_arn
    AvailabilityZones               = local.input_param_availability_zones
    Branch                          = var.build_branch
    BuildTag                        = var.build_tag
    BuildUrl                        = var.build_url
    BundleVersion                   = local.ami_build
    DeployMaxBatchSize              = local.as_max_batch_size
    DeployMinInstancesInService     = local.as_min_service
    Environment                     = local.input_param_deployment_environment
    HealthCheckGracePeriod          = local.health_check_grace_period
    InstanceProfile                 = local.input_param_iam_instance_profile_name
    InstanceType                    = local.instance_size
    LifecycleHookTerminating        = local.input_param_lifecycle_hook_terminating
    LoadBalancerName                = aws_elb.elb.id
    MsgHistoryV2BucketName          = var.msg_history_v2_bucket_name
    MsgHistoryV2DynamoDbTableName   = var.msg_history_v2_dynamodb
    MsgHistoryV2StreamName          = var.firehose_msg_history_v2_stream_name
    PolicyTargetValue               = local.as_policy_target_value
    S3CookbookRepositoryURL         = "//${local.input_param_cloud_templates_bucket_name}/${var.build_branch}/${var.build_number}/cookbooks.tar.gz"
    ScaleInOnWeekends               = local.as_scale_in_on_weekends
    ScaleInCron                     = local.as_cron_scale_down
    ScaleOutCron                    = local.as_cron_scale_up
    SecurityGroups                  = aws_security_group.security_group_ec2.id
    SpotPrice                       = "-1"
    StationVpcId                    = var.station_vpc_id
    StationVpcName                  = replace(var.station_name, "/-.*/", "")
    Vpc                             = local.input_param_vpc_id
    VpcZoneIdentifiers              = join(",", local.input_param_private_subnet_ids)
    VpcName                         = local.input_param_vpc_name
    XgemailBucketName               = var.outbound_submit_bucket
    XgemailMinSizeDataGB            = local.volume_size_gibs
    XgemailPolicyBucketName         = var.policy_bucket
    XgemailSnsSqsQueueUrl           = var.encryption_delivery_sqs_queue
    XgemailServiceType              = local.instance_type
    XgemailSxlDbl                   = local.sxl_dbl
    XgemailSxlRbl                   = local.sxl_rbl
  }
}