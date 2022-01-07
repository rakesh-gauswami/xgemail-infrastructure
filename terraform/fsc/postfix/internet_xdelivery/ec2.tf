locals {
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD = 2400
  DEFAULT_INSTANCE_SIZE                = "t2.small"
  DEFAULT_XGEMAIL_SIZE_DATA_GB         = 10

  AS_HEALTH_CHECK_GRACE_PERIOD_BY_ENVIRONMENT = {
    inf  = 2400
    dev  = 2400
    qa   = 2400
    prod = 2400
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
}


resource "aws_cloudformation_stack" "cloudformation_stack" {
  name          = "internet-xdelivery"
  template_body = file("${path.module}/templates/as_internet_xdelivery_template.json")
  parameters = {
    AccountName                     = local.input_param_account_name
    AmiId                           = data.aws_ami.ami.id
    AutoScalingInstanceRoleArn      = local.input_param_autoscaling_role_arn
    AutoScalingMinSize              = 1
    AutoScalingMaxSize              = 1
    AutoScalingNotificationTopicARN = local.input_param_lifecycle_topic_arn
    AvailabilityZoneIndex           = 0
    AvailabilityZones               = local.input_param_availability_zones
    Branch                          = var.build_branch
    BuildTag                        = var.build_tag
    BuildUrl                        = var.build_url
    BundleVersion                   = local.ami_build
    EbsMinIops                      = 0
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
    ScaleDownOnWeekends             = "true"
    SecurityGroups                  = aws_security_group.security_group_ec2.id
    SpotPrice                       = "-1"
    StationVpcId                    = var.station_vpc_id
    StationVpcName                  = replace(var.station_name, "/-.*/", "")
    VolumeSetId                     = "internet-xdelivery-1"
    VolumeTrackerSimpleDbDomain     = local.input_param_volume_tracker_simpledb_name
    Vpc                             = local.input_param_vpc_id
    VpcName                         = local.input_param_vpc_name
    VpcZoneIdentifiers              = join(",", local.input_param_public_subnet_ids)
    XgemailMinSizeDataGB            = local.xgemail_size_data_gb
    XgemailNotifierQueueUrl         = var.notifier_request_sqs_queue
    XgemailPolicyBucketName         = var.policy_bucket
    XgemailServiceType              = local.instance_type
  }
}
