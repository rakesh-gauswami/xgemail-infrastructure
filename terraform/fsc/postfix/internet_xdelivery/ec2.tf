locals {
  DEFAULT_AS_ALARM_SCALING_ENABLED     = false
  DEFAULT_AS_ALARM_SCALE_IN_THRESHOLD  = 10
  DEFAULT_AS_ALARM_SCALE_OUT_THRESHOLD = 50
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
  DEFAULT_XGEMAIL_SIZE_DATA_GB         = 10

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

  XGEMAIL_SIZE_DATA_GB_BY_ENVIRONMENT = {
    inf  = 10
    dev  = 40
    qa   = 70
    prod = 100
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

  xgemail_size_data_gb = lookup(
  local.XGEMAIL_SIZE_DATA_GB_BY_ENVIRONMENT,
  local.input_param_deployment_environment,
  local.DEFAULT_XGEMAIL_SIZE_DATA_GB
  )
}


resource "aws_cloudformation_stack" "cloudformation_stack" {
  name          = "internet-xdelivery"
  template_body = file("${path.module}/templates/as_internet_xdelivery_template.json")
  parameters = {
    AccountName                     = local.input_param_account_name
    AmiId                           = data.aws_ami.ami.id
    AutoScalingInstanceRoleArn      = local.input_param_autoscaling_role_arn
    AutoScalingMinSize              = "{{item.1}}"
    AutoScalingMaxSize              = 1
    AutoScalingNotificationTopicARN = local.input_param_lifecycle_topic_arn
    AvailabilityZoneIndex           = "{{item.2}}"
    AvailabilityZones               = local.input_param_availability_zones
    Branch                          = var.build_branch
    BuildTag                        = var.build_tag
    BuildUrl                        = var.build_url
    BundleVersion                   = local.ami_build
    EbsMinIops                      = "{{xgemail_iops_data_gb}}"
    Environment                     = local.input_param_deployment_environment
    HealthCheckGracePeriod          = local.health_check_grace_period
    InstanceProfile                 = local.input_param_iam_instance_profile_name
    InstanceType                    = local.instance_size
    LifecycleHookLaunching          = local.input_param_lifecycle_hook_launching
    LoadBalancerName                = aws_elb.elb.id
    MsgHistoryV2BucketName          = var.message_history_bucket
    MsgHistoryV2DynamoDbTableName   = var.message_history_dynamodb_table_name
    MsgHistoryV2StreamName          = var.firehose_msg_history_v2_stream_name
    S3CookbookRepositoryURL         = "//${local.input_param_cloud_templates_bucket_name}/${var.build_branch}/${var.build_number}/cookbooks.tar.gz"
    ScaleDownOnWeekends             =     "{{weekend_scale_down}}"
    SecurityGroups                  = aws_security_group.security_group_ec2.id
    SpotPrice                       = "-1"
    StationVpcId                    = var.station_vpc_id
    StationVpcName                  = replace(nonsensitive(var.station_name), "/-.*/", "")
    VolumeSetId                     =     "internet-xdelivery-{{item.0}}"
    VolumeTrackerSimpleDbDomain     =    "{{volume_tracker_sdb_output.ansible_facts.cloudformation[stack.sdb.volume_tracker_sdb].stack_outputs.SimpleDbDomain}}"
    Vpc                             = local.input_param_vpc_id
    VpcName                         = local.input_param_vpc_name
    VpcZoneIdentifiers              = join(",", local.input_param_public_subnet_ids)
    XgemailMinSizeDataGB            = local.xgemail_size_data_gb
    XgemailMsgHistoryStatusSnsArn   =   "{{sns.arn_prefix}}{{sns.msg_history_status_sns_topic}}"
    XgemailNotifierQueueUrl         =    "{{sqs.url_prefix}}{{sqs.notifier_request_sqs_queue}}"
    XgemailPolicyBucketName         = var.policy_bucket
    XgemailServiceType              = local.instance_type
  }
}
