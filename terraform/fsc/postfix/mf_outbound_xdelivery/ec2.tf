locals {
  DEFAULT_AS_HEALTH_CHECK_GRACE_PERIOD = 2400
  DEFAULT_INSTANCE_SIZE                = "t3.medium"
  DEFAULT_EBS_SIZE_DATA_GB             = 10
  DEFAULT_ZONE_INDEX = {
    1 = 0
    2 = 1
    3 = 2
  }
  DEFAULT_AS_MIN_SIZE = {
    1 = 1
    2 = 0
    3 = 0
  }

  AS_HEALTH_CHECK_GRACE_PERIOD_BY_ENVIRONMENT = {
    inf  = 2400
    dev  = 2400
    qa   = 2400
    prod = 2400
  }

  INSTANCE_SIZE_BY_ENVIRONMENT = {
    inf  = "t3.medium"
    dev  = "t3.medium"
    qa   = "t3.medium"
    prod = "m5.2xlarge"
  }

  EBS_SIZE_DATA_GB_BY_ENVIRONMENT = {
    inf  = 10
    dev  = 40
    qa   = 70
    prod = 100
  }

  AS_MIN_SIZE_BY_ENVIRONMENT = {
    inf = {
      1 = 1
      2 = 0
      3 = 0
    }
    dev = {
      1 = 1
      2 = 0
      3 = 0
    }
    qa = {
      1 = 1
      2 = 0
      3 = 0
    }
    prod = {
      1 = 1
      2 = 0
      3 = 0
    }
  }

  ZONE_INDEX_BY_ENVIRONMENT = {
    inf = {
      1 = 0
      2 = 1
      3 = 2
    }
    dev = {
      1 = 0
      2 = 1
      3 = 2
    }
    qa = {
      1 = 0
      2 = 1
      3 = 2
    }
    prod = {
      1 = 0
      2 = 1
      3 = 2
    }
  }
  as_min_size = lookup(
    local.AS_MIN_SIZE_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_AS_MIN_SIZE
  )

  ebs_size_data_gb = lookup(
    local.EBS_SIZE_DATA_GB_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_EBS_SIZE_DATA_GB
  )

  zone_index = lookup(
    local.ZONE_INDEX_BY_ENVIRONMENT,
    local.input_param_deployment_environment,
    local.DEFAULT_ZONE_INDEX
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


resource "aws_cloudformation_stack" "cloudformation_stack" {
  for_each      = local.zone_index
  name          = "${local.instance_type}-${each.key}"
  template_body = file("${path.module}/templates/as_mf_outbound_xdelivery_template.json")
  parameters = {
    AccountName                     = local.input_param_account_name
    AmiId                           = data.aws_ami.ami.id
    AutoScalingInstanceRoleArn      = local.input_param_autoscaling_role_arn
    AutoScalingMinSize              = local.as_min_size[each.key]
    AvailabilityZoneIndex           = each.value
    AutoScalingMaxSize              = 1
    AutoScalingNotificationTopicARN = local.input_param_lifecycle_topic_arn
    AvailabilityZones               = local.input_param_availability_zones
    Branch                          = var.build_branch
    BuildTag                        = var.build_tag
    BuildUrl                        = var.build_url
    BundleVersion                   = local.ami_build
    EbsMinIops                      = 0
    EbsMinSizeDataGB                = local.ebs_size_data_gb
    Environment                     = local.input_param_deployment_environment
    HealthCheckGracePeriod          = local.health_check_grace_period
    InstanceProfile                 = local.input_param_iam_instance_profile_name
    InstanceType                    = local.instance_size
    KmsKeyAlias                     = module.kms_key.key_alias_name
    LifecycleHookLaunching          = local.input_param_lifecycle_hook_launching
    LoadBalancerName                = aws_elb.elb.id
    MsgHistoryStatusSnsArn          = var.message_history_status_sns_topic
    MsgHistoryV2BucketName          = var.message_history_bucket
    MsgHistoryV2DynamoDbTableName   = var.message_history_dynamodb_table_name
    MsgHistoryV2StreamName          = var.message_history_v2_stream_name
    NotifierQueueUrl                = var.notifier_request_sqs_queue
    PolicyBucketName                = var.policy_bucket
    S3CookbookRepositoryURL         = "//${local.input_param_cloud_templates_bucket_name}/${var.build_branch}/${var.build_number}/cookbooks.tar.gz"
    ScaleDownOnWeekends             = "true"
    SdbRegion                       = "us-east-1"
    SecurityGroups                  = aws_security_group.security_group_ec2.id
    SpotPrice                       = "-1"
    StationAccountRoleArn           = var.station_account_role_arn
    StationVpcId                    = var.station_vpc_id
    StationVpcName                  = replace(var.station_name, "/-.*/", "")
    VolumeSetId                     = "${local.instance_type}-${each.key}"
    VolumeTrackerSimpleDbDomain     = local.input_param_volume_tracker_simpledb_name
    Vpc                             = local.input_param_vpc_id
    VpcName                         = local.input_param_vpc_name
    VpcZoneIdentifiers              = join(",", local.input_param_public_subnet_ids)
    XgemailServiceType              = local.instance_type
  }
}
