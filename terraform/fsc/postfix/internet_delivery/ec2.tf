locals {
  ami_owner_account = "843638552935"
  ami_type          = "xgemail"

  DEFAULT_AS_MIN_SIZE                   = 1
  DEFAULT_AS_MAX_SIZE                   = 6
  DEFAULT_AS_MIN_SERVICE                = 1
  DEFAULT_AS_MAX_BATCH_SIZE             = 1
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD  = 2400
  DEFAULT_INSTANCE_SIZE                 = "t2.small"
  DEFAULT_XGEMAIL_SIZE_DATA_GB          = 10
  DEFAULT_SXL_DBL                       = "uri.cal1.sophosxl.com"
  DEFAULT_SXL_RBL                       = "fur.cal1.sophosxl.com"

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

  INSTANCE_SIZE_BY_ENVIRONMENT = {
    inf  = "t2.small"
    dev  = "c4.xlarge"
    qa   = "c4.xlarge"
    prod = "m5.2xlarge"
  }

  XGEMAIL_SIZE_DATA_GB_BY_ENVIRONMENT = {
    inf  = 10
    dev  = 40
    qa   = 70
    prod = 100
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
  name = "internet-delivery"
  template_body = file("${path.module}/templates/as-internet-delivery-template.json")
  parameters = {
    AlarmTopicArn                     = local.input_param_alarm_topic_arn
    AmiId                             = data.aws_ami.ami
    AutoScalingInstanceRoleArn        = local.input_param_autoscaling_role_arn
    AutoScalingMinSize                = local.as_min_size
    AutoScalingMaxSize                = local.as_max_size
    AutoScalingNotificationTopicARN   = local.input_param_lifecycle_topic_arn
    AvailabilityZones                 = local.input_param_availability_zones
    Branch                            = var.build_branch
    BuildVersion                      = var.build_tag
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
    MsgHistoryV2BucketName            = var.message_history_bucket
    MsgHistoryV2DynamoDbTableName     = var.message_history_dynamodb_table_name
    MsgHistoryV2StreamName            = var.firehose_msg_history_v2_stream_name
    MessageHistoryEventsTopicArn      = var.message_history_events_sns_topic
    S3CookbookRepositoryURL           = "//${local.input_param_cloud_templates_bucket_name}/${var.build_branch}/xgemail-infrastructure/cookbooks.enc"
    SecurityGroups                    = [local.input_param_sg_base_id, aws_security_group.security_group_ec2]
    StationVpcId                      = var.station_vpc_id
    StationVpcName                    = var.station_name
    Vpc                               = local.input_param_vpc_id
    VpcName                           = "email"
    VpcZoneIdentifiers                = [local.input_param_public_subnet_ids]
    XgemailBucketName                 = var.customer_submit_bucket
    XgemailMinSizeDataGB              = local.xgemail_size_data_gb
    XgemailPolicyBucketName           = var.policy_bucket
    XgemailSnsSqsQueue                = var.internet_delivery_sqs_queue_name
    XgemailSnsSqsQueueUrl             = var.internet_delivery_sqs_queue_url
    XgemailServiceType                = local.instance_type
    XgemailSxlDbl                     = local.sxl_dbl
    XgemailSxlRbl                     = local.sxl_rbl
  }
}
